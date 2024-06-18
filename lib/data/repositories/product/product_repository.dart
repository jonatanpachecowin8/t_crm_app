import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:t_store/data/services/firebase_storage_service.dart';
import 'package:t_store/features/authentication/models/user_model.dart';
import 'package:t_store/features/shop/models/product_model.dart';
import 'package:t_store/utils/constants/enums.dart';
import 'package:t_store/utils/exceptions/firebase_exception.dart';
import 'package:t_store/utils/exceptions/format_exceptions.dart';
import 'package:t_store/utils/exceptions/platform_exceptions.dart';

/// Repository class for managing product-related data and operations.
class ProductRepository extends GetxController {
  static ProductRepository get instance => Get.find();

  /// Firestore instance for database interactions
  final _db = FirebaseFirestore.instance;

  /// Function to get limited featured products
  Future<List<ProductModel>> getFeaturedProducts() async {
    try {
      final snapshot = await _db.collection('Products').limit(4).get();
      print(snapshot.docs.map((document) => ProductModel.fromQuerySnapshot(document)).toList().length);
      return snapshot.docs.map((document) => ProductModel.fromQuerySnapshot(document)).toList();
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Function to get featured products
  Future<List<ProductModel>> getAllFeaturedProducts() async {
    try {
      final snapshot = await _db.collection('Product').where('IsFeatured', isEqualTo: true).get();
      return snapshot.docs.map((document) => ProductModel.fromSnapshot(document)).toList();
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get Products based on the Query
  Future<List<ProductModel>> fetchProductsByQuery(Query query) async {
    try {
      final querySnapshot = await query.get();
      final List<ProductModel> productList = querySnapshot.docs.map((doc) => ProductModel.fromQuerySnapshot(doc)).toList();
      return productList;
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get Products for brand
  Future<List<ProductModel>> getProductsForBrand({required String brandId, int limit = -1 }) async {
    try {
      final querySnapshot = limit == -1 ? await _db.collection('Products').where('Brand.Id',isEqualTo: brandId).get():
      await _db.collection('Products').where('Brand.Id',isEqualTo: brandId).limit(limit).get();
      final products = querySnapshot.docs.map((document) => ProductModel.fromSnapshot(document)).toList();
      return products;
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }


  /// Get Products for brand
  Future<List<ProductModel>> getProductsForCategory({required String categoryId, int limit = 4 }) async {
    try {
      // query to get all documents where productId matches the provided catgoryId and Fetch limited or unlimited based on limit
      final productCategoryQuery = limit == -1 ? await _db.collection('ProductCategory').where('categoryId',isEqualTo: categoryId).get():
      await _db.collection('ProductCategory').where('categoryId',isEqualTo: categoryId).limit(limit).get();

      // extract productIds from the documents
      List<String> productIds = productCategoryQuery.docs.map((doc) => doc['productId'] as String).toList();

      // query to get all documents where the brandId is in the list of brandIds, FieldPath.docuemtnId to query docuemtns in COllections
      final productsQuery = await _db.collection('Products').where(FieldPath.documentId, whereIn: productIds).get();

      // extract brand names or other relevant data from documents
      List<ProductModel> products = productsQuery.docs.map((document) => ProductModel.fromSnapshot(document)).toList();

      return products;
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }


  /// Get Products based on the Query
  Future<List<ProductModel>> getFavouriteProducts(List<String> productIds) async {
    try {
      final snapshot = await _db.collection('Products').where(FieldPath.documentId, whereIn: productIds).get();
      return snapshot.docs.map((doc) => ProductModel.fromSnapshot(doc)).toList();

    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }







  /// Upload dummy data to the cloud
  Future<void> uploadDummyData(List<ProductModel> products) async {
    try {
      final storage = Get.put(TFirebaseStorageService());

      // loop through each category
      for (var product in products) {
        // get imageData link from the local assets
        final thumbnail =
            await storage.getImageDataFromAssets(product.thumbnail);

        // upload image and get its url
        final url = await storage.uploadImageData(
            'Products/Images', thumbnail, product.thumbnail.toString());

        // assign URL to Category.image attribute
        product.thumbnail = url;

        // product list of images
        if (product.images != null && product.images!.isNotEmpty) {
          List<String> imagesUrl = [];
          for (var image in product.images!) {
            // get image data link from local assets
            final assetImage = await storage.getImageDataFromAssets(image);

            // upload image and get its url
            final url = await storage.uploadImageData(
                'Products/Images', assetImage, image);

            // assign URL to product.thumbnail attribute
            imagesUrl.add(url);
          }
          product.images!.clear();
          product.images!.addAll(imagesUrl);
        }

        // upload variation images
        if (product.productType == ProductType.variable.toString()) {
          for (var variation in product.productVariations!) {
            // get image data link from local assets
            final assetImage = await storage.getImageDataFromAssets(variation.image);

            // upload image and get its url
            final url = await storage.uploadImageData(
                'Products/Images', assetImage, variation.image);

            // assign URL to product.thumbnail attribute
            variation.image = url;
          }
        }

        // store product in firestore
        await _db.collection('Products').doc(product.id).set(product.toJson());
      }
    } on TFirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TFormatException catch (_) {
      throw const TFormatException();
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong: ${e.toString()}.';
    }
  }


  Future<void> addUser(UserModel user) async{
    try {
      await _db.collection('Users').doc(user.id).set({
        'Id': user.id,
        'FirstName': user.firstName,
        'LastName': user.lastName,
        'Username': user.username,
        'Email': user.email,
        'PhoneNumber': user.phoneNumber,
        'ProfilePicture': user.profilePicture,
      });
      print('Usuario agregado exitosamente.');
    } catch (e) {
      print('Error al agregar el usuario: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await _db.collection('Products').doc(product.id).set({
        'Id': product.id,
        'Stock': product.stock,
        'Sku': product.sku,
        'Price': product.price,
        'Title': product.title,
        'Date': product.date?.toIso8601String(),
        'SalePrice': product.salePrice,
        'Thumbnail': product.thumbnail,
        'IsFeatured': product.isFeatured,
        'Brand': {
          'Id': product.brand?.id,
          'Name': product.brand?.name,
          'Image': product.brand?.image,
          'IsFeatured': product.brand?.isFeatured,
          'ProductCount': product.brand?.productCount,
        },
        'Description': product.description,
        'CategoryId': product.categoryId,
        'Images': product.images,
        'ProductType': product.productType,
        'ProductAttributes': product.productAttributes?.map((attr) {
          return {
            'Name': attr.name,
            'Values': attr.values,
          };
        }).toList(),
        'ProductVariations': product.productVariations?.map((variation) {
          return {
            'Id': variation.id,
            'SKU': variation.sku,
            'Image': variation.image,
            'Description': variation.description,
            'Price': variation.price,
            'SalePrice': variation.salePrice,
            'Stock': variation.stock,
            'AttributeValues': variation.attributeValues,
          };
        }).toList(),
      });

      // IDs de los usuarios y productos
      List<String> userIds = ["12597","12596","12595","12594","12593","12592","12591","12588","12584","12585","e1hcFED2yAMsVD6Jjkk9tDxBbqi2","1", "2", "3","4", "5", "6"];
      List<String> productIds = ["123456", "234567", "345678", "456789", "567890", "678901", "789012", "890123","456783","345672","234561"];
      //String date = "202406";

      // interactions
      Random random = Random();

      // Generar y agregar 10 registros para cada usuario
      // for (var userId in userIds) {
      //   for (int i = 0; i < 3; i++) {
      //     String productId = productIds[random.nextInt(productIds.length)];
      //     String percentilUpSell = (random.nextDouble() * 1.0).toStringAsFixed(2);
      //
      //     Map<String, String> recommendationData = {
      //       "DateInit": date,
      //       "DateFin": date,
      //       "Percentil_UpSell": percentilUpSell,
      //       "ProductId": productId,
      //       "UserId": userId,
      //     };
      //
      //     await _db.collection('Recomendation_Base').add(recommendationData);
      //   }
      // }


      DateTime startDate = DateTime(2024, 5, 23, 10, 0, 0); // A las 10:00:00
      DateTime endDate = DateTime(2024, 6, 13, 23, 59, 59); // Hasta las 23:59:59 del 13 de junio de 2024

      // Generar una fecha aleatoria dentro del rango
      DateTime randomDate = generateRandomDate(startDate, endDate, random);

      //
      // Generar y agregar 10 registros para cada usuario
      for (var userId in userIds) {
        for (int i = 0; i < 6; i++) {
          String productId = productIds[random.nextInt(productIds.length)];
          String percentilUpSell = (random.nextDouble() * 1.0).toStringAsFixed(2);

          DateTime randomDate1 = generateRandomDate(startDate, endDate, random);
          DateTime randomDate2 = generateRandomDate(startDate, endDate, random);

          Map<String, String> interactionData = {
                  "DateInit": randomDate1.toString(),
                  "DateFin": randomDate2.toString(),
            "Percentil_UpSell": percentilUpSell,
            "ProductId": productId,
            "UserId": userId,
          };

          await _db.collection('Interactions').get();
        }



      }
    } catch (e) {
      print("Error adding product: $e");
    }
  }

  Future<void> addProducts(List<ProductModel> products) async {
    for (var product in products) {
      await addProduct(product);
    }
  }

  Future<void> addUsers(List<UserModel> user) async {
    for (var product in user) {
      await addUser(product);
    }
  }



  // Función para generar una fecha aleatoria entre startDate y endDate
  DateTime generateRandomDate(DateTime startDate, DateTime endDate, Random random) {
    Duration difference = endDate.difference(startDate);
    int randomMinutes = random.nextInt(difference.inMinutes); // Obtener minutos aleatorios dentro del rango
    return startDate.add(Duration(minutes: randomMinutes)); // Añadir minutos aleatorios a startDate
  }




  // DateTime generateRandomDate(DateTime startDate, DateTime endDate, Random random) {
  //   // Calcular la diferencia en días entre las fechas de inicio y fin
  //   int difference = endDate.difference(startDate).inDays;
  //
  //   // Generar un número aleatorio de días dentro del rango
  //   int randomDaysOffset = random.nextInt(difference);
  //
  //   // Sumar el número aleatorio de días al inicio del rango para obtener una fecha aleatoria
  //   DateTime randomDate = startDate.add(Duration(days: randomDaysOffset));
  //
  //   // Generar una hora aleatoria entre las 00:00 y las 23:59
  //   int randomHour = random.nextInt(24); // 0 a 23
  //   int randomMinute = random.nextInt(60); // 0 a 59
  //   int randomSecond = random.nextInt(60); // 0 a 59
  //
  //   // Devolver la fecha aleatoria con la hora generada
  //   return DateTime(
  //     randomDate.year,
  //     randomDate.month,
  //     randomDate.day,
  //     randomHour,
  //     randomMinute,
  //     randomSecond,
  //   );
  // }
  //


}
