
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductAttributeModel {
  String? name;
  final List<String>? values;

  ProductAttributeModel({
    this.name,
    this.values,
  });

  /// Convert model to JSON structure for sorting data in Firebase
  toJson() {
    return {
      'Name': name,
      'Values': values,
    };
  }

  // Empty helper function
  static ProductAttributeModel empty() =>
      ProductAttributeModel(name: '', values: []);

  /// Map json oriented document snapshot from firebase to Category Model
  factory ProductAttributeModel.fromJson(Map<String, dynamic> document) {
    final data = document;
    if (data.isEmpty) return ProductAttributeModel();
    return ProductAttributeModel(
      name: data.containsKey('Name') ? data['Name'] : '',
      values: List<String>.from(data['Values']),
    );
  }


  factory ProductAttributeModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() == null) return ProductAttributeModel.empty();
    final data = document.data()!;
    print(data);
    return ProductAttributeModel(
      name: data['Name'] ?? '',
      values: List<String>.from(data['Values']) ?? [],
    );
  }
}
