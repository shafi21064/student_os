import 'package:flutter/material.dart';
import 'package:studentos/data/models.dart';

const searchPlaceholders = <String>[
  'Search courses...',
  'Find internships...',
  'Best student discounts',
  'Cheap lunch nearby',
  'Find tuition',
  'Ask StudentOS AI',
];

const initialTasks = <TaskItem>[
  TaskItem(id: 1, title: 'Finish assignment', completed: true),
  TaskItem(id: 2, title: 'Buy groceries', completed: false),
  TaskItem(id: 3, title: 'Attend class', completed: false),
  TaskItem(id: 4, title: 'Submit lab report', completed: false),
];

const shopCategories = <String>[
  'All', 'Electronics', 'Books', 'Beauty', 'Men', 'Women', 'Lifestyle', 'Health',
];

const careerCategories = <String>[
  'All', 'Programming', 'AI', 'Business', 'Design', 'Language', 'Marketing',
];

const cuisines = <String>[
  'All', 'Fast Food', 'Pizza', 'Asian', 'Café', 'Healthy', 'Desserts',
];

const courses = <CatalogItem>[
  CatalogItem(
    id: 'flutter-bootcamp', title: 'Flutter Bootcamp', subtitle: 'Udemy', emoji: '📱',
    price: '৳1,200', originalPrice: '৳4,000', badge: '70% OFF', rating: 4.8,
    category: 'Programming', background: Color(0xFFDBEAFE),
    description: 'Build production-ready mobile apps with Dart, Flutter, clean architecture, testing, and deployment workflows.',
  ),
  CatalogItem(
    id: 'data-science-pro', title: 'Data Science Pro', subtitle: 'Coursera', emoji: '📊',
    price: '৳2,500', originalPrice: '৳8,000', badge: '69% OFF', rating: 4.9,
    category: 'AI', background: Color(0xFFEDE9FE),
    description: 'A project-led path covering Python, statistics, machine learning, visualization, and portfolio development.',
  ),
  CatalogItem(
    id: 'ielts-masterclass', title: 'IELTS Masterclass', subtitle: 'British Council', emoji: '🌍',
    price: '৳1,800', originalPrice: '৳5,500', badge: '67% OFF', rating: 4.7,
    category: 'Language', background: Color(0xFFDCFCE7),
    description: 'Structured preparation for listening, reading, writing, and speaking with practice assessments.',
  ),
  CatalogItem(
    id: 'uiux-design', title: 'UI/UX Design', subtitle: 'Designlab', emoji: '🎨',
    price: '৳1,500', originalPrice: '৳4,500', badge: '67% OFF', rating: 4.8,
    category: 'Design', background: Color(0xFFFCE7F3),
    description: 'Learn product thinking, research, wireframing, visual design, prototyping, and portfolio presentation.',
  ),
];

const internships = <CatalogItem>[
  CatalogItem(
    id: 'pathao-frontend', title: 'Frontend Intern', subtitle: 'Pathao', emoji: '🚀',
    price: '৳12,000/mo', badge: 'Part-time', location: 'Dhaka', meta: 'Applications close Jul 30',
    background: Color(0xFFDBEAFE), category: 'Programming',
    description: 'Work with a product engineering team to build responsive interfaces, reusable components, and tested user flows.',
  ),
  CatalogItem(
    id: 'shopup-data', title: 'Data Analyst Intern', subtitle: 'ShopUp', emoji: '📊',
    price: '৳15,000/mo', badge: 'Full-time', location: 'Remote', meta: 'Applications close Aug 3',
    background: Color(0xFFEDE9FE), category: 'AI',
    description: 'Support business teams with SQL analysis, dashboards, experiments, and clear insight communication.',
  ),
  CatalogItem(
    id: 'brac-finance', title: 'Finance Intern', subtitle: 'Brac Bank', emoji: '🏦',
    price: '৳10,000/mo', badge: 'Part-time', location: 'Dhaka', meta: 'Applications close Aug 7',
    background: Color(0xFFDCFCE7), category: 'Business',
    description: 'Assist with reporting, reconciliation, operational analysis, and structured financial research.',
  ),
];

const shopProducts = <CatalogItem>[
  CatalogItem(id: 'ipad-air-m2', title: 'iPad Air M2', subtitle: 'Apple Education', emoji: '📱', price: '৳75,000', originalPrice: '৳82,000', badge: '9% OFF', rating: 4.8, category: 'Electronics', background: Color(0xFFDBEAFE), description: 'Portable study and creation device with a student-exclusive offer.'),
  CatalogItem(id: 'airpods-pro', title: 'AirPods Pro', subtitle: 'Campus Tech', emoji: '🎧', price: '৳28,000', originalPrice: '৳35,000', badge: '20% OFF', rating: 4.9, category: 'Electronics', background: Color(0xFFEDE9FE), description: 'Noise-cancelling earbuds for focused study, calls, and commuting.'),
  CatalogItem(id: 'study-lamp', title: 'Study Desk Lamp', subtitle: 'StudySpace', emoji: '💡', price: '৳1,800', originalPrice: '৳2,500', badge: '28% OFF', rating: 4.6, category: 'Lifestyle', background: Color(0xFFFEF3C7), description: 'Adjustable eye-comfort desk lighting with USB charging.'),
  CatalogItem(id: 'notebook-set', title: 'Notebook Set', subtitle: 'Paper & Co.', emoji: '📓', price: '৳450', originalPrice: '৳600', badge: '25% OFF', rating: 4.5, category: 'Books', background: Color(0xFFDCFCE7), description: 'A durable set of ruled notebooks for class notes and planning.'),
  CatalogItem(id: 'usb-c-hub', title: 'USB-C Hub', subtitle: 'TechNest', emoji: '🔌', price: '৳3,200', originalPrice: '৳4,000', badge: '20% OFF', rating: 4.7, category: 'Electronics', background: Color(0xFFFEE2E2), description: 'Multi-port USB-C adapter for presentations, storage, and peripherals.'),
  CatalogItem(id: 'protein-powder', title: 'Protein Powder', subtitle: 'Campus Fitness', emoji: '💪', price: '৳2,800', originalPrice: '৳3,500', badge: '20% OFF', rating: 4.4, category: 'Health', background: Color(0xFFFCE7F3), description: 'Student-priced nutrition product from a verified marketplace seller.'),
];

const marketplaceProducts = <CatalogItem>[
  CatalogItem(id: 'macbook-air-m3', title: 'MacBook Air M3', subtitle: 'Verified retailer', emoji: '💻', price: '৳1,20,000', badge: '8% OFF', rating: 4.9, category: 'Electronics', background: Color(0xFFDBEAFE), description: 'Student pricing on a lightweight laptop for coding and creative work.'),
  CatalogItem(id: 'sony-xm5', title: 'Sony WH-1000XM5', subtitle: 'Verified retailer', emoji: '🎧', price: '৳32,000', badge: '15% OFF', rating: 4.8, category: 'Electronics', background: Color(0xFFEDE9FE), description: 'Premium noise cancellation and long battery life for study sessions.'),
  CatalogItem(id: 'mech-keyboard', title: 'Mech Keyboard', subtitle: 'Campus seller', emoji: '⌨️', price: '৳8,500', badge: '20% OFF', rating: 4.6, category: 'Electronics', background: Color(0xFFFEE2E2), description: 'Compact mechanical keyboard suitable for coding and writing.'),
  CatalogItem(id: 'backpack-pro', title: 'Backpack Pro', subtitle: 'Verified retailer', emoji: '🎒', price: '৳3,200', badge: '25% OFF', rating: 4.7, category: 'Lifestyle', background: Color(0xFFDCFCE7), description: 'Water-resistant student backpack with laptop protection.'),
  CatalogItem(id: 'textbook-bundle', title: 'Textbook Bundle', subtitle: 'Campus bookstore', emoji: '📚', price: '৳4,500', badge: '30% OFF', rating: 4.5, category: 'Books', background: Color(0xFFFEF3C7), description: 'A discounted bundle of core course textbooks.'),
  CatalogItem(id: 'bottle', title: 'Insulated Bottle', subtitle: 'Campus seller', emoji: '💧', price: '৳850', badge: '10% OFF', rating: 4.5, category: 'Lifestyle', background: Color(0xFFCFFAFE), description: 'Reusable insulated bottle for campus days.'),
];

const tuitionJobs = <CatalogItem>[
  CatalogItem(id: 'tuition-physics', title: 'Physics Tutor', subtitle: 'Class 11–12', emoji: '⚛️', price: '৳3,000/mo', location: 'Dhanmondi', meta: '1.2 km', badge: '3 days/week', category: 'Science', background: Color(0xFFDBEAFE), description: 'Support an HSC student with Physics concepts and exam preparation.'),
  CatalogItem(id: 'tuition-math', title: 'Mathematics Tutor', subtitle: 'Class 9–10', emoji: '➗', price: '৳2,500/mo', location: 'Mirpur', meta: '2.8 km', badge: '3 days/week', category: 'Math', background: Color(0xFFEDE9FE), description: 'Teach secondary mathematics with weekly practice and progress updates.'),
  CatalogItem(id: 'tuition-english', title: 'English Tutor', subtitle: 'Class 6–8', emoji: '🔤', price: '৳2,000/mo', location: 'Uttara', meta: '3.5 km', badge: '2 days/week', category: 'Language', background: Color(0xFFDCFCE7), description: 'Improve grammar, reading comprehension, and writing confidence.'),
  CatalogItem(id: 'tuition-chemistry', title: 'Chemistry Tutor', subtitle: 'Class 11–12', emoji: '🧪', price: '৳3,200/mo', location: 'Mohammadpur', meta: '2.1 km', badge: '3 days/week', category: 'Science', background: Color(0xFFFCE7F3), description: 'Teach HSC Chemistry with practical examples and exam-focused revision.'),
  CatalogItem(id: 'tuition-ict', title: 'ICT Tutor', subtitle: 'Class 9–12', emoji: '💻', price: '৳2,800/mo', location: 'Farmgate', meta: '1.9 km', badge: '2 days/week', category: 'Technology', background: Color(0xFFCFFAFE), description: 'Cover programming fundamentals, databases, networking, and board preparation.'),
];

const buySellListings = <CatalogItem>[
  CatalogItem(id: 'used-calculus', title: 'Calculus Textbook', subtitle: 'Nafisa · CUET campus', emoji: '📘', price: '৳650', badge: 'Like New', location: 'CUET', category: 'Books', background: Color(0xFFDBEAFE), description: 'Clean copy with a few highlighted formulas and no missing pages.'),
  CatalogItem(id: 'used-cycle', title: 'Phoenix Bicycle', subtitle: 'Sajid · Palashi', emoji: '🚲', price: '৳6,500', badge: 'Good', location: 'Palashi', category: 'Transport', background: Color(0xFFDCFCE7), description: 'Regularly serviced campus bicycle with lock included.'),
  CatalogItem(id: 'used-monitor', title: '24-inch Monitor', subtitle: 'Arif · Dhanmondi', emoji: '🖥️', price: '৳9,000', badge: 'Used', location: 'Dhanmondi', category: 'Electronics', background: Color(0xFFEDE9FE), description: 'Full HD monitor in working condition with HDMI cable and stand.'),
  CatalogItem(id: 'used-drafter', title: 'Engineering Drafter', subtitle: 'Mim · CUET campus', emoji: '📐', price: '৳1,100', badge: 'Like New', location: 'CUET', category: 'Study', background: Color(0xFFFEF3C7), description: 'Engineering drawing tool in excellent condition.'),
];

const restaurants = <CatalogItem>[
  CatalogItem(id: 'kfc', title: 'KFC Bangladesh', subtitle: 'Fried Chicken', emoji: '🍗', price: '20% Student Off', badge: 'Free Coleslaw', rating: 4.5, meta: '25–35 min', category: 'Fast Food', background: Color(0xFFFEF3C7), description: 'Student-exclusive combo offers and delivery discounts.'),
  CatalogItem(id: 'pizza-hut', title: 'Pizza Hut', subtitle: 'Pizza & Pasta', emoji: '🍕', price: '15% Student Off', badge: 'Free Garlic Bread', rating: 4.3, meta: '30–45 min', category: 'Pizza', background: Color(0xFFFEE2E2), description: 'Pizza, pasta, and sharing meals with verified student pricing.'),
  CatalogItem(id: 'burger-king', title: 'Burger King', subtitle: 'Burgers & Fries', emoji: '🍔', price: '18% Student Off', badge: 'Free Size Upgrade', rating: 4.4, meta: '20–30 min', category: 'Fast Food', background: Color(0xFFFEF9C3), description: 'Campus-friendly meal offers and quick delivery.'),
  CatalogItem(id: 'daily-grind', title: 'The Daily Grind', subtitle: 'Coffee & Snacks', emoji: '☕', price: '25% Student Off', badge: 'Free Cookie', rating: 4.7, meta: '10–15 min', category: 'Café', background: Color(0xFFEDE9FE), description: 'Coffee, snacks, and study-friendly café deals.'),
];

const foodDishes = <CatalogItem>[
  CatalogItem(id: 'zinger-meal', title: 'Zinger Meal', subtitle: 'KFC Bangladesh', emoji: '🍗', price: '৳320', originalPrice: '৳390', badge: 'Hot', rating: 4.6, meta: '25 min', category: 'Fast Food', background: Color(0xFFFEF3C7), description: 'Crispy chicken burger meal with fries and a drink.'),
  CatalogItem(id: 'pepperoni-pizza', title: 'Pepperoni Pizza', subtitle: 'Pizza Hut', emoji: '🍕', price: '৳450', originalPrice: '৳550', rating: 4.5, meta: '35 min', category: 'Pizza', background: Color(0xFFFEE2E2), description: 'Student-sized pepperoni pizza with a promotional price.'),
  CatalogItem(id: 'avocado-toast', title: 'Avocado Toast', subtitle: 'The Daily Grind', emoji: '🥑', price: '৳220', originalPrice: '৳260', badge: 'Hot', rating: 4.7, meta: '12 min', category: 'Café', background: Color(0xFFEDE9FE), description: 'Fresh avocado toast, ideal for a light campus meal.'),
  CatalogItem(id: 'beef-biryani', title: 'Beef Biryani', subtitle: 'Dhakai Kitchen', emoji: '🍛', price: '৳250', originalPrice: '৳300', rating: 4.5, meta: '40 min', category: 'Asian', background: Color(0xFFFEF3C7), description: 'A filling biryani meal with student pricing.'),
  CatalogItem(id: 'double-cheeseburger', title: 'Double Cheeseburger', subtitle: 'Burger King', emoji: '🍔', price: '৳290', originalPrice: '৳360', badge: 'Hot', rating: 4.4, meta: '20 min', category: 'Fast Food', background: Color(0xFFFEF9C3), description: 'Double cheeseburger with an exclusive student discount.'),
];

const events = <CatalogItem>[
  CatalogItem(id: 'tech-fest', title: 'Tech Fest 2025', subtitle: 'CUET CS Club', emoji: '🎤', price: 'Free', badge: 'Technology', location: 'CUET Auditorium', meta: 'Jul 20 · 10:00 AM', background: Color(0xFFDBEAFE), description: 'Talks, demos, student projects, and networking with local technology teams.'),
  CatalogItem(id: 'art-expo', title: 'Art & Design Expo', subtitle: 'Creative Guild', emoji: '🎨', price: '৳50', badge: 'Design', location: 'TSC, DU', meta: 'Jul 22 · 2:00 PM', background: Color(0xFFEDE9FE), description: 'A student showcase of illustration, visual design, and interactive media.'),
  CatalogItem(id: 'hackathon', title: 'Hackathon 48HR', subtitle: 'BASIS Student Forum', emoji: '🏆', price: 'Free', badge: 'Competition', location: 'ICT Tower', meta: 'Jul 25 · 9:00 AM', background: Color(0xFFDCFCE7), description: 'Build and present a working product with a multidisciplinary team.'),
  CatalogItem(id: 'career-fair', title: 'Career Fair 2025', subtitle: 'CUET Career Center', emoji: '📊', price: 'Free', badge: 'Career', location: 'CUET Gym', meta: 'Aug 2 · 11:00 AM', background: Color(0xFFFEF3C7), description: 'Meet employers, explore graduate roles, and review your CV.'),
  CatalogItem(id: 'cultural-night', title: 'Cultural Night', subtitle: 'CUET Cultural Club', emoji: '🎵', price: '৳100', badge: 'Cultural', location: 'CUET Field', meta: 'Aug 5 · 6:00 PM', background: Color(0xFFFCE7F3), description: 'An evening of music, performances, and student community activities.'),
];

const expenseCategories = <ExpenseCategory>[
  ExpenseCategory(label: 'Food', percentage: 35, color: Color(0xFF6D4AFF), spent: 1820),
  ExpenseCategory(label: 'Transport', percentage: 20, color: Color(0xFF16A34A), spent: 1040),
  ExpenseCategory(label: 'Education', percentage: 25, color: Color(0xFF8B5CF6), spent: 1300),
  ExpenseCategory(label: 'Shopping', percentage: 15, color: Color(0xFFF59E0B), spent: 780),
  ExpenseCategory(label: 'Other', percentage: 5, color: Color(0xFF94A3B8), spent: 260),
];

const initialTransactions = <TransactionItem>[
  TransactionItem(id: 'tx1', emoji: '🍕', label: 'Pizza Hut', category: 'Food', amount: -320, date: 'Today, 1:30 PM'),
  TransactionItem(id: 'tx2', emoji: '🚌', label: 'Bus Pass', category: 'Transport', amount: -200, date: 'Today, 9:00 AM'),
  TransactionItem(id: 'tx3', emoji: '📚', label: 'Textbook PDF', category: 'Education', amount: -450, date: 'Yesterday'),
  TransactionItem(id: 'tx4', emoji: '☕', label: 'The Daily Grind', category: 'Food', amount: -180, date: 'Yesterday'),
  TransactionItem(id: 'tx5', emoji: '💻', label: 'Udemy Course', category: 'Education', amount: -850, date: 'Jul 13'),
  TransactionItem(id: 'tx6', emoji: '🛒', label: 'Grocery Store', category: 'Shopping', amount: -620, date: 'Jul 12'),
];

const initialNotes = <NoteItem>[
  NoteItem(id: 1, title: 'Data Structures Notes', body: 'Binary trees, AVL, Red-Black trees — exam focus on rotations.', color: Color(0xFFDBEAFE), date: 'Jul 14'),
  NoteItem(id: 2, title: 'IELTS Vocabulary', body: 'Academic wordlist: ubiquitous, paradigm, empirical, methodology...', color: Color(0xFFDCFCE7), date: 'Jul 13'),
  NoteItem(id: 3, title: 'Project Ideas', body: '1. AI-powered study planner  2. Campus food ordering app  3. Exam prep tool', color: Color(0xFFFEF9C3), date: 'Jul 10'),
];

const notifications = <NotificationItem>[
  NotificationItem(id: 'n1', title: 'New internship match', body: 'Pathao posted a Frontend Intern role that matches your skills.', time: '10 min ago', icon: Icons.work_outline_rounded, color: Color(0xFF7C3AED), unread: true),
  NotificationItem(id: 'n2', title: 'Budget reminder', body: 'You have 35% of your July budget remaining.', time: '1 hr ago', icon: Icons.account_balance_wallet_outlined, color: Color(0xFF2563EB), unread: true),
  NotificationItem(id: 'n3', title: 'Student deal unlocked', body: 'A new electronics discount is available in Shop.', time: '3 hrs ago', icon: Icons.local_offer_outlined, color: Color(0xFF22C55E), unread: true),
  NotificationItem(id: 'n4', title: 'Task completed', body: 'Finish assignment was marked complete.', time: 'Yesterday', icon: Icons.task_alt_rounded, color: Color(0xFFF59E0B), unread: false),
];

const faqItems = <Map<String, String>>[
  {'q': 'How do I verify my student status?', 'a': 'Open Student ID from More and submit your institution email or valid student document. This prototype simulates the verified state.'},
  {'q': 'How are student discounts applied?', 'a': 'Eligible offers show a Student badge. Open the item, review the terms, and use the action button to claim or purchase.'},
  {'q': 'Can I edit my monthly budget?', 'a': 'Yes. Open Budget Manager, select a month, and tap Edit Budget.'},
  {'q': 'How do I post something for sale?', 'a': 'Open Buy & Sell, switch to Post an Item, complete the fields, and submit the listing.'},
  {'q': 'Does StudentOS store payment information?', 'a': 'This UI prototype does not connect to a payment processor or store real payment credentials.'},
];

const monthBudgets = <String, int>{
  'Jan 2025': 7000, 'Feb 2025': 7000, 'Mar 2025': 7500, 'Apr 2025': 7500,
  'May 2025': 8000, 'Jun 2025': 8000, 'Jul 2025': 8000, 'Aug 2025': 8000,
  'Sep 2025': 8500, 'Oct 2025': 8500, 'Nov 2025': 9000, 'Dec 2025': 9000,
};

const monthSpent = <String, int>{
  'Jan 2025': 6200, 'Feb 2025': 5800, 'Mar 2025': 7100, 'Apr 2025': 6400,
  'May 2025': 7200, 'Jun 2025': 7600, 'Jul 2025': 5200, 'Aug 2025': 0,
  'Sep 2025': 0, 'Oct 2025': 0, 'Nov 2025': 0, 'Dec 2025': 0,
};

CatalogItem? findCatalogItem(String kind, String id) {
  final List<CatalogItem> source = switch (kind) {
    'course' => courses,
    'job' => internships,
    'product' => shopProducts,
    'marketplace' => marketplaceProducts,
    'food' => foodDishes,
    'restaurant' => restaurants,
    'tuition' => tuitionJobs,
    'buysell' => buySellListings,
    'event' => events,
    _ => const <CatalogItem>[],
  };
  for (final item in source) {
    if (item.id == id) return item;
  }
  return null;
}

List<CatalogItem> allSearchableItems() => <CatalogItem>[
      ...courses,
      ...internships,
      ...shopProducts,
      ...marketplaceProducts,
      ...foodDishes,
      ...restaurants,
      ...tuitionJobs,
      ...buySellListings,
      ...events,
    ];
