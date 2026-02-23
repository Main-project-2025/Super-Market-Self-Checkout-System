import '../models/product_model.dart';

// ============== MOCK DATA ==============
const List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'Fresh Milk',
    price: 1.50,
    barcode: '111111',
    imageUrl:
        'https://images.unsplash.com/photo-1550583724-125581f77833?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '2',
    name: 'Brown Bread',
    price: 2.20,
    barcode: '222222',
    imageUrl:
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '3',
    name: 'Organic Eggs (12)',
    price: 4.50,
    barcode: '333333',
    imageUrl:
        'https://images.unsplash.com/photo-1506976785307-8732e854ad03?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '4',
    name: 'Avocado',
    price: 1.80,
    barcode: '444444',
    imageUrl:
        'https://images.unsplash.com/photo-1523049673857-d163d092d6e4?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '5',
    name: 'Chicken Breast',
    price: 8.99,
    barcode: '555555',
    imageUrl:
        'https://images.unsplash.com/photo-1604503468506-a8da13d82791?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '6',
    name: 'Cheddar Cheese',
    price: 5.40,
    barcode: '666666',
    imageUrl:
        'https://images.unsplash.com/photo-1618161595730-388b0377041c?auto=format&fit=crop&w=400&q=80',
  ),
];

const List<Product> mockRecommendations = [
  Product(
    id: '7',
    name: 'Greek Yogurt',
    price: 3.25,
    barcode: '777777',
    imageUrl:
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '8',
    name: 'Almond Milk',
    price: 2.99,
    barcode: '888888',
    imageUrl:
        'https://images.unsplash.com/photo-1563453392212-326f5e854473?auto=format&fit=crop&w=400&q=80',
  ),
  Product(
    id: '9',
    name: 'Whole Wheat Pasta',
    price: 1.75,
    barcode: '999999',
    imageUrl:
        'https://images.unsplash.com/photo-1563636619-e9143da7973b?auto=format&fit=crop&w=400&q=80',
  ),
];
