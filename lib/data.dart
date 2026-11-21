class AppImages {
  static const khapli = 'assets/images/pack-khapli.png';
  static const protein = 'assets/images/pack-protein.png';
  static const lineup = 'assets/images/pack-lineup.png';
  static const badges = 'assets/images/pack-badges.png';
  static const duo = 'assets/images/pack-duo.png';
  static const handle = 'assets/images/pack-handle.png';
  static const roti = 'assets/images/lifestyle-roti.jpg';
  static const chakki = 'assets/images/story-chakki.jpg';
}

String money(int value) {
  final s = value.abs().toString();
  String grouped;
  if (s.length <= 3) {
    grouped = s;
  } else {
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final buf = StringBuffer();
    for (var i = 0; i < rest.length; i++) {
      if (i > 0 && (rest.length - i) % 2 == 0) buf.write(',');
      buf.write(rest[i]);
    }
    grouped = '${buf.toString()},$last3';
  }
  return '${value < 0 ? '-' : ''}₹$grouped';
}

class ProductSize {
  final String label;
  final int price;
  final int mrp;
  final String? id;
  final String? description;
  final bool inStock;
  final int? stockCount;
  const ProductSize(this.label, this.price, this.mrp, {
    this.id, this.description, this.inStock = true, this.stockCount,
  });
}

class Product {
  final String id;
  final String name;
  final String subtitle;
  final String origin;
  final double rating;
  final int reviews;
  final String image;
  final String tag;
  final List<String> groups;
  final List<ProductSize> sizes;
  final String? databaseId;
  final String? fallbackImage;
  final List<String> gallery;
  final bool featured;
  final String description;
  final String batch;
  final Map<String, String> nutritionFacts;

  const Product({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.origin,
    required this.rating,
    required this.reviews,
    required this.image,
    required this.tag,
    required this.groups,
    required this.sizes,
    this.databaseId,
    this.fallbackImage,
    this.gallery = const [],
    this.featured = false,
    this.description = '',
    this.batch = '',
    this.nutritionFacts = const {},
  });
}

class CategoryItem {
  final String name;
  final String note;
  final String image;
  final String filter;
  const CategoryItem(this.name, this.note, this.image, this.filter);
}

class HeroSlide {
  final String pill;
  final String title;
  final String accent;
  final String tail;
  final String description;
  final String image;
  final int productIndex;
  const HeroSlide({
    required this.pill,
    required this.title,
    required this.accent,
    required this.tail,
    required this.description,
    required this.image,
    required this.productIndex,
  });
}

class LabTest {
  final String name;
  final String result;
  final String method;
  const LabTest(this.name, this.result, this.method);
}

class Bundle {
  final String name;
  final String description;
  final int price;
  final int mrp;
  final String image;
  final String tag;
  const Bundle(this.name, this.description, this.price, this.mrp, this.image, this.tag);
}

class RankedItem {
  final String name;
  final double rating;
  final int price;
  final String size;
  final String image;
  const RankedItem(this.name, this.rating, this.price, this.size, this.image);
}

class TimelineStep {
  final String title;
  final String detail;
  const TimelineStep(this.title, this.detail);
}

class NotificationItem {
  final String title;
  final String body;
  final String time;
  const NotificationItem(this.title, this.body, this.time);
}

class ViewerTab {
  final String label;
  final int index;
  const ViewerTab(this.label, this.index);
}

const products = <Product>[
  Product(
    id: 'khapli',
    name: 'Khapli Ancient Atta',
    subtitle: '100% Emmer Wheat · Low GI 42',
    origin: 'Solapur & Sangli',
    rating: 5.0,
    reviews: 342,
    image: AppImages.khapli,
    tag: 'Bestseller',
    groups: ['All', 'Khapli'],
    sizes: [
      ProductSize('1 kg', 95, 115),
      ProductSize('2 kg', 185, 225),
      ProductSize('5 kg', 440, 520),
      ProductSize('10 kg', 849, 999),
    ],
  ),
  Product(
    id: 'protein',
    name: 'High Protein Atta',
    subtitle: '36g Protein · Wheat + Soya + Peanut',
    origin: 'Malwa & Indore',
    rating: 4.9,
    reviews: 388,
    image: AppImages.protein,
    tag: 'Fitness Pick',
    groups: ['All', 'Protein'],
    sizes: [
      ProductSize('1 kg', 115, 140),
      ProductSize('2 kg', 220, 270),
      ProductSize('5 kg', 495, 599),
      ProductSize('10 kg', 949, 1120),
    ],
  ),
  Product(
    id: 'lineup',
    name: 'Khapli Complete Lineup',
    subtitle: '1kg · 2kg · 5kg · 10kg Range',
    origin: 'Solapur & Sangli',
    rating: 5.0,
    reviews: 274,
    image: AppImages.lineup,
    tag: '4 Pack Sizes',
    groups: ['All', 'Khapli', 'Family'],
    sizes: [
      ProductSize('1 kg', 95, 115),
      ProductSize('5 kg', 440, 520),
      ProductSize('10 kg', 849, 999),
    ],
  ),
  Product(
    id: 'badges',
    name: '4 Health Badges Edition',
    subtitle: 'High Protein · Nutrition · Natural',
    origin: 'Solapur & Sangli',
    rating: 4.9,
    reviews: 198,
    image: AppImages.badges,
    tag: 'Lab Certified',
    groups: ['All', 'Khapli'],
    sizes: [
      ProductSize('1 kg', 99, 120),
      ProductSize('5 kg', 440, 520),
      ProductSize('10 kg', 849, 999),
    ],
  ),
  Product(
    id: 'duo',
    name: 'Protein Duo Pack',
    subtitle: '2 × 5kg High Protein Blend',
    origin: 'Malwa & Indore',
    rating: 5.0,
    reviews: 312,
    image: AppImages.duo,
    tag: 'Save 17%',
    groups: ['All', 'Protein', 'Bundle'],
    sizes: [
      ProductSize('5 kg', 495, 599),
      ProductSize('10 kg', 960, 1150),
    ],
  ),
];

const categories = <CategoryItem>[
  CategoryItem('Khapli Atta', 'Ancient Low-GI', AppImages.khapli, 'Khapli'),
  CategoryItem('High Protein', '36g Protein', AppImages.protein, 'Protein'),
  CategoryItem('Family Sacks', '5kg & 10kg', AppImages.handle, 'Family'),
  CategoryItem('Certified Pure', '4 Lab Badges', AppImages.badges, 'Khapli'),
  CategoryItem('Protein Duo', 'Wheat · Soya · Peanut', AppImages.duo, 'Protein'),
  CategoryItem('Carry Handle', 'Reinforced Bags', AppImages.handle, 'Family'),
];

const heroSlides = <HeroSlide>[
  HeroSlide(
    pill: 'NEW HARVEST COLLECTION • 100% COLD STONEGROUND',
    title: 'Discover The',
    accent: 'Purest',
    tail: 'Chakki Atta Online',
    description: 'Shop 100% honest stoneground flours milled below 28°C. Triple-washed grains, full bran retention, zero maida, zero bleaching agents.',
    image: AppImages.khapli,
    productIndex: 0,
  ),
  HeroSlide(
    pill: '36g PROTEIN • WHEAT + SOYA + PEANUT',
    title: 'Flour that',
    accent: 'works',
    tail: 'harder for you.',
    description: 'Cold-stoneground high-protein blend for softer rotis, better hydration and all-day energy.',
    image: AppImages.protein,
    productIndex: 1,
  ),
  HeroSlide(
    pill: 'FAMILY SACKS • 1KG – 10KG',
    title: 'One sack,',
    accent: 'all',
    tail: 'month of rotis.',
    description: 'The same honest Khapli atta in carry-handle and family sizes, delivered fresh by EV van.',
    image: AppImages.lineup,
    productIndex: 2,
  ),
];

const viewerPacks = <String>[
  AppImages.khapli,
  AppImages.protein,
  AppImages.lineup,
  AppImages.badges,
  AppImages.duo,
  AppImages.handle,
];

const labTests = <LabTest>[
  LabTest('Added Maida / Refined Starch', 'Not Detected', 'NABL · FTIR Spectroscopy'),
  LabTest('Benzoyl Peroxide (Bleach)', '0.00 ppm', 'NABL · HPLC'),
  LabTest('Chalk / Added Fillers', 'Not Detected', 'NABL · Gravimetric'),
  LabTest('Potassium Bromate', 'Not Detected', 'NABL · IC'),
  LabTest('Bran Retention', '100%', 'In-house sieve analysis'),
  LabTest('Peak Milling Temperature', '27.4°C', 'Continuous probe log'),
];

const nutrition = <Map<String, String>>[
  {'label': 'Energy', 'value': '341 kcal'},
  {'label': 'Protein', 'value': '14.5 g'},
  {'label': 'Dietary Fibre', 'value': '12.1 g'},
  {'label': 'Carbohydrate', 'value': '69.4 g'},
  {'label': 'Fat (natural germ oils)', 'value': '2.1 g'},
  {'label': 'Glycemic Index', 'value': '42 · Low'},
  {'label': 'Water Absorption', 'value': '72 – 75%'},
  {'label': 'Added Maida / Bleach', 'value': 'Nil'},
];

const bundles = <Bundle>[
  Bundle('Family Health Starter Kit', 'Complete monthly stoneground nutrition for a family of four.', 1249, 1499, AppImages.lineup, 'Best Value'),
  Bundle('High Protein & Fitness Duo', 'Engineered for active athletes and post-workout recovery.', 960, 1150, AppImages.duo, 'Fitness Favourite'),
  Bundle('Diabetic & Ancient Grain Care', 'Low-GI grain rotation recommended by clinical nutritionists.', 880, 1040, AppImages.badges, 'Doctor Recommended'),
];

const ranked = <RankedItem>[
  RankedItem('Khapli Ancient Atta', 5.0, 95, '1 kg', AppImages.khapli),
  RankedItem('High Protein Atta', 4.9, 115, '1 kg', AppImages.protein),
  RankedItem('Khapli 10kg Family Pack', 4.9, 849, '10 kg', AppImages.handle),
  RankedItem('4 Health Badges Edition', 4.9, 440, '5 kg', AppImages.badges),
];

const timeline = <TimelineStep>[
  TimelineStep('Order confirmed', 'We received your order at 9:41 AM'),
  TimelineStep('Batch allocated', 'Batch #IC-0426 · 6/6 lab tests passed'),
  TimelineStep('Stone-milled', 'Milled below 28°C within 24 hours'),
  TimelineStep('Packed & sealed', 'Exact itsclear™ pouch, tamper-evident'),
  TimelineStep('On the way', 'Climate-controlled EV van · ~94 mins'),
];

const notifications = <NotificationItem>[
  NotificationItem('Order #IC40821 delivered', 'Your Khapli 10kg sack arrived in 94 minutes.', 'Today, 9:41 AM'),
  NotificationItem('New harvest is live', 'Batch #IC-0426 is milled below 28°C and lab-tested.', 'Yesterday'),
  NotificationItem('CLEAR50 is waiting', 'Get ₹50 off your next stoneground order.', '2 days ago'),
  NotificationItem('EV delivery expanded', '2-hour delivery is now available at pincode 226001.', '4 days ago'),
];

const categoryFilters = <String>['All', 'Khapli', 'Protein', 'Family', 'Bundle'];
const sortLabels = <String>['Featured', 'Price', 'Rating'];
const viewerTabs = <ViewerTab>[
  ViewerTab('Front', 0),
  ViewerTab('Handle', 5),
  ViewerTab('Range', 2),
];
