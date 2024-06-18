import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:t_store/data/repositories/product/product_repository.dart';
import 'package:t_store/features/shop/models/product_model.dart';
import 'package:t_store/utils/popups/loaders.dart';

class AllProductsController extends GetxController {
  static AllProductsController get instance => Get.find();

  /// Variables
  final repository = ProductRepository.instance;
  final RxString selectedSortOption = 'Name'.obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;

  @override
  void onInit() {
    // fetchFeaturedProducts();
    super.onInit();
  }

  /// Selected attribute and variation
  Future<List<ProductModel>> fetchProductsByQuery(Query? query) async {
    try {
      // show loader while loading categories
      if (query == null) return [];

      final products = await repository.fetchProductsByQuery(query);
      print(products);
      return products;
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Oh snap', message: e.toString());
    } finally {
      return [];
    }
  }

  void sortProducts(String sortOption) {
    selectedSortOption.value = sortOption;

    switch (sortOption) {
      case 'Name':
        products.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'Higher Price':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Lower Price':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Newest':
        products.sort((a, b) => a.date!.compareTo(b.date!));
        break;
      case 'Sale':
        products.sort((a, b) {
          if(b.salePrice > 0) {
            return b.salePrice.compareTo(a.salePrice);
          } else if (a.salePrice > 0) {
            return -1;
          } else {
            return 1;
          }
        });
        break;
      default:
        // default sorting option name
        products.sort((a, b) => a.title.compareTo(b.title));
    }
  }


  void assignProducts(List<ProductModel> products){
    // assign products to the product list
    this.products.assignAll(products);
    sortProducts('Name');
  }
}
