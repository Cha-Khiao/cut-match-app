import 'package:latlong2/latlong.dart';

class Salon {
  final String id;
  final String name;
  final String address;
  final LatLng location;
  final String phone; // ✨ [FIX] เพิ่ม property นี้

  Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.location,
    required this.phone, // ✨ [FIX] เพิ่มใน Constructor
  });

  factory Salon.fromJson(Map<String, dynamic> json) {
    return Salon(
      id: json['_id'],
      name: json['name'],
      address: json['address'],
      location: LatLng(
        json['location']['coordinates'][1], // Latitude
        json['location']['coordinates'][0], // Longitude
      ),
      phone: json['phone'] ?? '', // ✨ [FIX] ดึงข้อมูล phone จาก json
    );
  }
}