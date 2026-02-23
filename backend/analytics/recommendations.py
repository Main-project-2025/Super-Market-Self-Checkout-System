import sqlite3
import json
import os
import sys
import pandas as pd
from collections import Counter, defaultdict
import argparse

# Database path
DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'database', 'checkout.db')

# Seed affinities: "bought X -> recommend Y" for the 9 products when there are no transactions yet.
# Product ids: 1=Milk, 2=Bread, 3=Eggs, 4=Avocado, 5=Chicken, 6=Cheese, 7=Yogurt, 8=Almond Milk, 9=Pasta
PRODUCT_AFFINITIES = {
    '1': ['2', '3', '6'],           # Milk -> Bread, Eggs, Cheese
    '2': ['1', '6', '7', '8'],      # Bread -> Milk, Cheese, Yogurt, Almond Milk (e.g. jam-like)
    '3': ['1', '2', '6'],           # Eggs -> Milk, Bread, Cheese
    '4': ['3', '2'],                # Avocado -> Eggs, Bread
    '5': ['4', '6'],                # Chicken -> Avocado, Cheese
    '6': ['2', '1', '9'],           # Cheese -> Bread, Milk, Pasta
    '7': ['1', '2', '8'],           # Yogurt -> Milk, Bread, Almond Milk
    '8': ['9', '2', '7'],           # Almond Milk -> Pasta, Bread, Yogurt
    '9': ['6', '4'],                # Pasta -> Cheese, Avocado
}

def get_db_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def get_recommendations(user_id=None, limit=5, current_items=None):
    """
    Generates product recommendations.
    1. If user_id is provided, look at their recent purchases.
    2. Find items frequently bought together with their recent purchases (Co-occurrence).
    3. Only for unauthenticated requests: fill with top selling items.
    """
    # Reject invalid/missing user_id so we never return global top sellers for an authenticated request
    if user_id is not None and isinstance(user_id, str):
        user_id = user_id.strip()
        if user_id in ('', 'undefined', 'null', 'none'):
            return []
    if user_id is not None and not str(user_id).strip():
        return []

    if current_items:
        current_items = [str(x).strip() for x in current_items]  # Strip whitespace just in case

    try:
        conn = get_db_connection()
        
        # 1. Get all transactions for co-occurrence matrix
        # We need transaction_id and product_id
        query = """
            SELECT t.id as transaction_id, ti.product_id
            FROM transactions t
            JOIN transaction_items ti ON t.id = ti.transaction_id
        """
        all_transactions_df = pd.read_sql_query(query, conn)
        
        # Build Co-occurrence Matrix
        # Map product_id -> { related_product_id: count }
        co_occurrence = defaultdict(Counter)
        
        # Group by transaction
        grouped = all_transactions_df.groupby('transaction_id')['product_id'].apply(list)
        
        for products in grouped:
            for i in range(len(products)):
                for j in range(len(products)):
                    if i != j:
                        p1, p2 = products[i], products[j]
                        co_occurrence[str(p1)][str(p2)] += 1

        # 2. Get User's recent history (if user_id provided)
        user_history_ids = []
        if user_id:
            user_history_query = """
                SELECT ti.product_id
                FROM transactions t
                JOIN transaction_items ti ON t.id = ti.transaction_id
                WHERE t.user_id = ?
                ORDER BY t.created_at DESC
                LIMIT 10
            """
            user_history_df = pd.read_sql_query(user_history_query, conn, params=(user_id,))
            user_history_ids = [str(x) for x in user_history_df['product_id'].tolist()]

        # New users with no purchase history and no current cart get no recommendations
        if user_id and not user_history_ids and (not current_items or len(current_items) == 0):
            conn.close()
            return []

        # 3. Build "related products" from DB co-occurrence, or seed affinities when no transactions (bread -> milk, etc.)
        def get_related_with_scores(product_id, weight=1):
            pid = str(product_id)
            out = []
            if co_occurrence and pid in co_occurrence:
                for rid, count in co_occurrence[pid].items():
                    out.append((str(rid), count * weight))
            if pid in PRODUCT_AFFINITIES:
                for rid in PRODUCT_AFFINITIES[pid]:
                    out.append((rid, 1 * weight))
            return out

        # 4. Generate candidates only from this user's purchase history and current cart
        candidates = Counter()
        seen_bought = set(user_history_ids) | set(current_items or [])

        # 4a. Current cart (higher weight)
        if current_items:
            for product_id in current_items:
                for rid, score in get_related_with_scores(product_id, weight=2):
                    if rid not in seen_bought:
                        candidates[rid] += score
        # 4b. User's purchase history (what they bought -> recommend related)
        for product_id in user_history_ids:
            for rid, score in get_related_with_scores(product_id, weight=1):
                if rid not in seen_bought:
                    candidates[rid] += score
        
        # 5. Finalize List (only products related to what this user bought or has in cart; exclude what they already have)
        recommended_ids = [pid for pid, score in candidates.most_common()]
        recommended_ids = [pid for pid in recommended_ids if str(pid) not in seen_bought]
        
        # Option A: For "Just For You" (when user_id is set), do NOT add global top sellers.
        # Return only personalized recommendations; may be fewer than limit.
        if not user_id:
            # No user context: use global top sellers as fallback/filler
            top_sellers_query = """
                SELECT product_id, COUNT(*) as count
                FROM transaction_items
                GROUP BY product_id
                ORDER BY count DESC
                LIMIT 20
            """
            top_sellers_df = pd.read_sql_query(top_sellers_query, conn)
            top_sellers_ids = top_sellers_df['product_id'].tolist()
            for pid in top_sellers_ids:
                seller_id_str = str(pid)
                if seller_id_str in [str(x) for x in recommended_ids]:
                    continue
                if current_items and seller_id_str in current_items:
                    continue
                recommended_ids.append(pid)
        
        # Take top N (for user_id, may be fewer than limit)
        final_ids = recommended_ids[:limit]
        
        if not final_ids:
            return []

        # 6. Fetch Product Details
        placeholders = ','.join(['?'] * len(final_ids))
        details_query = f"""
            SELECT id, name, price, barcode, image_url, description
            FROM products
            WHERE id IN ({placeholders})
        """
        # We need to preserve order, so we'll fetch then re-sort
        products_df = pd.read_sql_query(details_query, conn, params=final_ids)
        conn.close()
        
        if products_df.empty:
            return []
        products_df['id'] = products_df['id'].astype(str)
        products_map = products_df.set_index('id').to_dict('index')

        results = []
        for pid in final_ids:
            pk = str(pid)
            if pk in products_map:
                item = dict(products_map[pk])
                item['id'] = pk
                pid_key = pk
                if candidates.get(pid_key, 0) > 0:
                    if current_items and any(pid_key in co_occurrence.get(c_item, {}) for c_item in current_items):
                        item['recommendation_reason'] = 'Goes well with your cart'
                    else:
                        item['recommendation_reason'] = 'Frequently bought with your items'
                else:
                    item['recommendation_reason'] = 'Popular item'
                results.append(item)
                
        return results

    except Exception as e:
        return {'error': str(e)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate product recommendations')
    parser.add_argument('--user_id', type=str, help='User ID for personalized recommendations')
    parser.add_argument('--limit', type=int, default=5, help='Number of recommendations to return')
    parser.add_argument('--current_items', type=str, help='Comma-separated list of product IDs in current cart')
    
    args = parser.parse_args()
    
    current_items = []
    if args.current_items:
        current_items = args.current_items.split(',')
        
    result = get_recommendations(user_id=args.user_id, limit=args.limit, current_items=current_items)
    print(json.dumps(result, indent=2))
