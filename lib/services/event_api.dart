class Event {
  final String title;
  final String location;
  final String date;
  final String image;
  final String price;

  Event({
    required this.title,
    required this.location,
    required this.date,
    required this.image,
    required this.price,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    final venue = json['_embedded']?['venues']?[0];
    final images = json['images'] as List?;
    return Event(
      title: json['name'] ?? 'Unknown Event',
      location: venue?['city']?['name'] ?? 'Unknown Location',
      date: json['dates']?['start']?['localDate'] ?? 'TBA',
      image: images != null && images.isNotEmpty
          ? images.first['url']
          : 'https://via.placeholder.com/400x200.png?text=No+Image',
      price: json['priceRanges'] != null
          ? '\$${json['priceRanges'][0]['min'].toString()}+'
          : 'Price TBD',
    );
  }
}
