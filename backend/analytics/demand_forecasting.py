"""
demand_forecasting.py — ARIMA-based demand forecasting
=======================================================
Uses ARIMA(p,d,q) via statsmodels for products with sufficient sales history.
Falls back to a simple moving-average for products with sparse data (<7 data points).

ARIMA parameters (auto-selected simple defaults):
  p=1  — use yesterday's demand to predict today's
  d=1  — first-order differencing to make series stationary
  q=0  — no moving-average term (keeps it close to AR(I)MA)

These defaults work well for short, noisy retail time series.
For more data, consider auto_arima from pmdarima.
"""

import sqlite3
import json
import os
import sys
import warnings
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

# Suppress ARIMA convergence warnings (common with sparse data, handled by fallback)
warnings.filterwarnings("ignore")

try:
    from statsmodels.tsa.arima.model import ARIMA
    ARIMA_AVAILABLE = True
except ImportError:
    ARIMA_AVAILABLE = False

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'database', 'checkout.db'
)

# Minimum daily data points required to run ARIMA (else use moving average)
ARIMA_MIN_POINTS = 7

# Default ARIMA order — simple, robust for retail demand
ARIMA_ORDER = (1, 1, 0)


# ---------------------------------------------------------------------------
# DB helpers
# ---------------------------------------------------------------------------
def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


# ---------------------------------------------------------------------------
# Trend detection: compare first vs second half of the series
# ---------------------------------------------------------------------------
def compute_trend(series: pd.Series) -> str:
    """Return 'rising', 'falling', or 'stable' by comparing half-periods."""
    if series is None or len(series) < 4:
        return 'stable'
    mid = len(series) // 2
    first_half_avg = series.iloc[:mid].mean()
    second_half_avg = series.iloc[mid:].mean()
    if first_half_avg == 0:
        return 'stable'
    change = (second_half_avg - first_half_avg) / first_half_avg
    if change > 0.10:
        return 'rising'
    elif change < -0.10:
        return 'falling'
    return 'stable'


# ---------------------------------------------------------------------------
# ARIMA forecast for a single product
# ---------------------------------------------------------------------------
def arima_forecast(daily_series: pd.Series, forecast_days: int) -> dict:
    """
    Fit ARIMA(1,1,0) on `daily_series` and return forecasts for
    the given time horizons.

    Returns a dict with keys: forecast_7d, forecast_14d, forecast_30d,
    daily_demand_rate, method.
    """
    try:
        # Reindex to fill missing dates with 0 (no sales on that day)
        date_range = pd.date_range(start=daily_series.index.min(),
                                   end=daily_series.index.max(),
                                   freq='D')
        series_filled = daily_series.reindex(date_range, fill_value=0).astype(float)

        model = ARIMA(series_filled, order=ARIMA_ORDER)
        result = model.fit()

        # Forecast max(forecast_days, 30) steps ahead
        steps = max(forecast_days, 30)
        forecast_values = result.forecast(steps=steps)

        # Clip negatives (demand can't be negative)
        forecast_values = np.clip(forecast_values, 0, None)

        forecast_7d  = round(float(forecast_values[:7].sum()),  1)
        forecast_14d = round(float(forecast_values[:14].sum()), 1)
        forecast_30d = round(float(forecast_values[:30].sum()), 1)
        daily_rate   = round(float(forecast_values[:forecast_days].mean()), 3)

        return {
            'forecast_7d': forecast_7d,
            'forecast_14d': forecast_14d,
            'forecast_30d': forecast_30d,
            'daily_demand_rate': daily_rate,
            'method': 'ARIMA(1,1,0)',
        }

    except Exception:
        # ARIMA failed — fall through to moving average
        return None


# ---------------------------------------------------------------------------
# Moving average fallback
# ---------------------------------------------------------------------------
def moving_average_forecast(total_sold: int, days_history: int, forecast_days: int) -> dict:
    """Simple moving-average forecast — used when ARIMA can't run."""
    daily_rate = total_sold / days_history if days_history > 0 else 0
    return {
        'forecast_7d':  round(daily_rate * 7,  1),
        'forecast_14d': round(daily_rate * 14, 1),
        'forecast_30d': round(daily_rate * 30, 1),
        'daily_demand_rate': round(daily_rate, 3),
        'method': 'MovingAverage',
    }


# ---------------------------------------------------------------------------
# Main forecast entry point
# ---------------------------------------------------------------------------
def forecast_demand(days_history: int = 30, forecast_days: int = 7) -> dict:
    """
    Predict per-product demand for the next `forecast_days` days.

    Returns:
      success, summary (overall numbers), forecasts (per-product list
      sorted by restock urgency).
    """
    try:
        conn = get_db_connection()

        # 1. Current inventory
        products_df = pd.read_sql_query(
            "SELECT id, name, category, stock_quantity, price FROM products WHERE is_active = 1",
            conn
        )

        # 2. Daily sales history
        cutoff_date = (datetime.now() - timedelta(days=days_history)).strftime('%Y-%m-%d')
        sales_query = f"""
            SELECT
                ti.product_id,
                DATE(t.created_at)  AS sale_date,
                SUM(ti.quantity)    AS qty_sold
            FROM transaction_items ti
            JOIN transactions t ON ti.transaction_id = t.id
            WHERE t.created_at >= '{cutoff_date}'
              AND t.status IN ('paid', 'pending')
            GROUP BY ti.product_id, DATE(t.created_at)
        """
        daily_sales_df = pd.read_sql_query(sales_query, conn)
        conn.close()

        if products_df.empty:
            return {'success': True, 'summary': {}, 'forecasts': []}

        forecasts = []
        arima_count = 0
        fallback_count = 0

        for _, product in products_df.iterrows():
            pid = product['id']
            current_stock = int(product['stock_quantity'])

            # Filter daily sales for this product
            prod_daily = daily_sales_df[daily_sales_df['product_id'] == pid].copy()
            total_sold = int(prod_daily['qty_sold'].sum()) if not prod_daily.empty else 0

            fcast = None

            # --- Try ARIMA if enough data points ---
            if (
                ARIMA_AVAILABLE
                and not prod_daily.empty
                and len(prod_daily) >= ARIMA_MIN_POINTS
            ):
                prod_series = (
                    prod_daily
                    .set_index(pd.to_datetime(prod_daily['sale_date']))
                    ['qty_sold']
                    .astype(float)
                )
                fcast = arima_forecast(prod_series, forecast_days)
                if fcast:
                    arima_count += 1

            # --- Fallback to moving average ---
            if fcast is None:
                fcast = moving_average_forecast(total_sold, days_history, forecast_days)
                fallback_count += 1

            daily_rate = fcast['daily_demand_rate']

            # Trend detection (on raw daily data regardless of model)
            if not prod_daily.empty:
                series_for_trend = (
                    prod_daily
                    .set_index('sale_date')
                    .sort_index()['qty_sold']
                )
                trend = compute_trend(series_for_trend)
            else:
                trend = 'stable'

            # Restock logic
            projected_demand = daily_rate * forecast_days
            restock_needed   = projected_demand > current_stock
            restock_qty      = max(0, round(fcast['forecast_30d'] - current_stock))
            days_until_stockout = (
                round(current_stock / daily_rate, 1) if daily_rate > 0 else None
            )

            forecasts.append({
                'product_id':           pid,
                'product_name':         product['name'],
                'category':             product['category'] or 'Uncategorized',
                'current_stock':        current_stock,
                'price':                float(product['price']),
                'units_sold_history':   total_sold,
                'history_days':         days_history,
                'daily_demand_rate':    daily_rate,
                'demand_trend':         trend,
                'forecast_7d':          fcast['forecast_7d'],
                'forecast_14d':         fcast['forecast_14d'],
                'forecast_30d':         fcast['forecast_30d'],
                'days_until_stockout':  days_until_stockout,
                'restock_needed':       restock_needed,
                'restock_quantity':     restock_qty,
                'forecast_method':      fcast['method'],
            })

        # Sort by urgency: restock items first, then by days until stockout asc
        forecasts.sort(key=lambda x: (
            0 if x['restock_needed'] else 1,
            x['days_until_stockout'] if x['days_until_stockout'] is not None else float('inf')
        ))

        restock_items = [f for f in forecasts if f['restock_needed']]
        summary = {
            'total_products':           len(forecasts),
            'products_needing_restock': len(restock_items),
            'total_restock_units':      sum(f['restock_quantity'] for f in restock_items),
            'history_days':             days_history,
            'forecast_horizon_days':    forecast_days,
            'arima_forecasts':          arima_count,
            'fallback_forecasts':       fallback_count,
            'arima_available':          ARIMA_AVAILABLE,
            'generated_at':             datetime.now().isoformat(),
        }

        return {'success': True, 'summary': summary, 'forecasts': forecasts}

    except Exception as e:
        return {'success': False, 'error': str(e)}


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
if __name__ == '__main__':
    # Usage: python3 demand_forecasting.py [days_history] [forecast_days]
    days_history  = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    forecast_days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    result = forecast_demand(days_history=days_history, forecast_days=forecast_days)
    print(json.dumps(result, indent=2))
