class Cafe {
  final String id;
  final String name;
  final String location;
  final String address;
  final String description;
  final double rating;
  final double distanceKm;
  final String priceLevel;

  const Cafe({
    required this.id,
    required this.name,
    required this.location,
    required this.address,
    required this.description,
    required this.rating,
    required this.distanceKm,
    required this.priceLevel,
  });

  String get distanceLabel => '${distanceKm.toStringAsFixed(1)} km';
}

List<Cafe> sampleCafes() {
  return const [
    Cafe(
      id: 'cafe-1',
      name: 'Brew House',
      location: 'Jakarta Selatan',
      address: 'Jl. Melati No. 12',
      description: 'Tempat santai untuk kerja dan ngobrol dengan menu kopi khas roastery.',
      rating: 4.8,
      distanceKm: 0.8,
      priceLevel: 'Rp 25k - 60k',
    ),
    Cafe(
      id: 'cafe-2',
      name: 'Morning Roast',
      location: 'Bandung',
      address: 'Jl. Dago No. 45',
      description: 'Interior hangat dengan area outdoor dan pilihan pastry harian.',
      rating: 4.6,
      distanceKm: 1.4,
      priceLevel: 'Rp 20k - 55k',
    ),
    Cafe(
      id: 'cafe-3',
      name: 'Bean Spot',
      location: 'Yogyakarta',
      address: 'Jl. Kaliurang Km 5',
      description: 'Cocok untuk study session dengan Wi-Fi stabil dan banyak colokan.',
      rating: 4.7,
      distanceKm: 2.1,
      priceLevel: 'Rp 18k - 50k',
    ),
  ];
}
