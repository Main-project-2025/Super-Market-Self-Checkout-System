import sqlite3
import json
import os
import sys
from datetime import datetime, timedelta
import pandas as pd

# Database path
DB_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'database', 'checkout.db'
)

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def compute_trend(df_product_daily):
    """
    Given a daily-sales Series (indexed by date), returns:
    'rising', 'stable', or 'falling' by comparing first-half vs second-half averages.
    """
    if df_product_daily is None or len(df_product_daily) < 4:
        return 'stable'
    mid = len(df_product_daily) // 2
    first_half_avg = df_product_daily.iloc[:mid].mean()
    second_half_avg = df_product_daily.iloc[mid:].mean()
    if first_half_avg == 0:
        return 'stable'
    change = (second_half_avg - first_half_avg) / first_half_avg
    if change > 0.10:
        return 'rising'
    elif change < -0.10:
        return 'falling'
    return 'stable'


def forecast_demand(days_history=30, forecast_days=7):
    """
    Predicts per-product demand for the next `forecast_days` days
    based on `days_history` of purchase history and current stock levels.

    Returns a dict with:
      - summary: overall numbers
      - forecasts: per-product list sorted by restock urgency
    """
    try:
        conn = get_db_connection()

        # 1. Current inventory
        products_df = pd.read_sql_query(
            "SELECT id, name, category, stock_quantity, price FROM products WHERE is_active = 1",
            conn
        )

        # 2. Sales history — daily granularity for trend detection
        cutoff_date = (datetime.now() - timedelta(days=days_history)).strftime('%Y-%m-%d')
        sales_query = f"""
            SELECT
                ti.product_id,
                DATE(t.created_at) AS sale_date,
                SUM(ti.quantity)   AS qty_sold
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

        for _, product in products_df.iterrows():
            pid = product['id']
            current_stock = int(product['stock_quantity'])

            # Filter daily sales for this product
            prod_daily = daily_sales_df[daily_sales_df['product_id'] == pid].copy()

            # Total sold in history window
            total_sold = int(prod_daily['qty_sold'].sum()) if not prod_daily.empty else 0

            # Average daily demand (velocity)
            daily_rate = total_sold / days_history if days_history > 0 else 0

            # Per-horizon forecasts
            forecast_7d  = round(daily_rate * 7,  1)
            forecast_14d = round(daily_rate * 14, 1)
            forecast_30d = round(daily_rate * 30, 1)

            # Trend: compare demand in first vs second half of history window
            if not prod_daily.empty:
                prod_daily = prod_daily.set_index('sale_date').sort_index()
                trend = compute_trend(prod_daily['qty_sold'])
            else:
                trend = 'stable'

            # Restock logic: flag if projected demand in `forecast_days` days exceeds stock
            projected_demand = daily_rate * forecast_days
            restock_needed = projected_demand > current_stock

            # Recommend enough stock for 30 days of demand
            restock_qty = max(0, round(forecast_30d - current_stock))

            # Days until stockout
            if daily_rate > 0:
                days_until_stockout = round(current_stock / daily_rate, 1)
            else:
                days_until_stockout = None  # no velocity → unknown

            forecasts.append({
                'product_id': pid,
                'product_name': product['name'],
                'category': product['category'] or 'Uncategorized',
                'current_stock': current_stock,
                'price': float(product['price']),
                'units_sold_history': total_sold,
                'history_days': days_history,
                'daily_demand_rate': round(daily_rate, 3),
                'demand_trend': trend,
                'forecast_7d': forecast_7d,
                'forecast_14d': forecast_14d,
                'forecast_30d': forecast_30d,
                'days_until_stockout': days_until_stockout,
                'restock_needed': restock_needed,
                'restock_quantity': restock_qty,
            })

        # Sort: restock-needed products first (by urgency = days_until_stockout asc)
        forecasts.sort(key=lambda x: (
            0 if x['restock_needed'] else 1,
            x['days_until_stockout'] if x['days_until_stockout'] is not None else float('inf')
        ))

        # Summary
        restock_items = [f for f in forecasts if f['restock_needed']]
        summary = {
            'total_products': len(forecasts),
            'products_needing_restock': len(restock_items),
            'total_restock_units': sum(f['restock_quantity'] for f in restock_items),
            'history_days': days_history,
            'forecast_horizon_days': forecast_days,
            'generated_at': datetime.now().isoformat(),
        }

        return {
            'success': True,
            'summary': summary,
            'forecasts': forecasts,
        }

    except Exception as e:
        return {'success': False, 'error': str(e)}


if __name__ == '__main__':
    # Allow CLI args: python3 demand_forecasting.py [days_history] [forecast_days]
    days_history = int(sys.argv[1]) if len(sys.argv) > 1 else 30
    forecast_days = int(sys.argv[2]) if len(sys.argv) > 2 else 7
    result = forecast_demand(days_history=days_history, forecast_days=forecast_days)
    print(json.dumps(result, indent=2))
