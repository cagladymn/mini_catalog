
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/book.dart';
import 'pages/book_detail_page.dart';

void main() {
  runApp(const MiniCatalogApp());
}

class MiniCatalogApp extends StatelessWidget {
  const MiniCatalogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kitaplık',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> books = [];
  List<Book> filteredBooks = [];

  final TextEditingController searchController =
      TextEditingController();

  bool isLoading = true;
  String selectedCategory = 'Tümü';

  final Set<int> cartBookIds = {};

  final List<String> categories = [
    'Tümü',
    'Roman',
    'Klasikler',
    'Bilim Kurgu',
    'Romantik',
    'Macera',
  ];

  @override
  void initState() {
    super.initState();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/books.json');

      final List<dynamic> jsonList = jsonDecode(jsonString);

      final List<Book> loadedBooks = jsonList
          .map(
            (item) => Book.fromJson(item as Map<String, dynamic>),
          )
          .toList();

      if (!mounted) return;

      setState(() {
        books = loadedBooks;
        filteredBooks = loadedBooks;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void filterBooks() {
    final query = searchController.text.toLowerCase().trim();

    setState(() {
      filteredBooks = books.where((book) {
        final matchesSearch =
            book.title.toLowerCase().contains(query) ||
            book.author.toLowerCase().contains(query);

        final matchesCategory = selectedCategory == 'Tümü' ||
            book.category == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void addToCart(Book book) {
    if (cartBookIds.contains(book.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book.title} zaten sepette.'),
        ),
      );
      return;
    }

    setState(() {
      cartBookIds.add(book.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${book.title} sepete eklendi!'),
      ),
    );
  }

  void openCart() {
    final List<Book> cartBooks = books
        .where((book) => cartBookIds.contains(book.id))
        .toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final total = cartBooks.fold<double>(
              0,
              (sum, book) => sum + book.price,
            );

            return SizedBox(
              height: MediaQuery.of(sheetContext).size.height * 0.65,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shopping_cart_outlined,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sepetim (${cartBooks.length})',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: cartBooks.isEmpty
                        ? const Center(
                            child: Text('Sepetiniz boş.'),
                          )
                        : ListView.builder(
                            itemCount: cartBooks.length,
                            itemBuilder: (context, index) {
                              final book = cartBooks[index];

                              return ListTile(
                                leading: Image.asset(
                                  book.imageAsset,
                                  width: 40,
                                  height: 55,
                                  fit: BoxFit.contain,
                                  errorBuilder: (
                                    context,
                                    error,
                                    stackTrace,
                                  ) {
                                    return const Icon(
                                      Icons.menu_book,
                                      size: 35,
                                    );
                                  },
                                ),
                                title: Text(book.title),
                                subtitle: Text(
                                  '${book.price.toStringAsFixed(2)} TL',
                                ),
                                trailing: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      cartBookIds.remove(book.id);
                                    });

                                    setSheetState(() {
                                      cartBooks.removeWhere(
                                        (item) => item.id == book.id,
                                      );
                                    });
                                  },
                                  child: const Text(
                                    'Kaldır',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (cartBooks.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Toplam:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${total.toStringAsFixed(2)} TL',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kitaplık',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            padding: const EdgeInsets.only(right: 16),
            tooltip: 'Sepetim',
            onPressed: openCart,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_cart_outlined),
                const SizedBox(width: 4),
                Text('${cartBookIds.length}'),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (_) => filterBooks(),
              decoration: InputDecoration(
                hintText: 'Kitap veya yazar ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        selectedCategory = category;
                      });
                      filterBooks();
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : books.isEmpty
                    ? const Center(
                        child: Text(
                          'Kitaplar yüklenemedi.\n'
                          'JSON ve pubspec.yaml dosyalarını kontrol et.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : filteredBooks.isEmpty
                        ? const Center(
                            child: Text(
                              'Aramana uygun kitap bulunamadı.',
                            ),
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(12),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.68,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];

                              return Card(
                                clipBehavior: Clip.antiAlias,
                                elevation: 3,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            BookDetailPage(book: book),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Image.asset(
                                              book.imageAsset,
                                              height: 130,
                                              fit: BoxFit.contain,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Icon(
                                                  Icons.menu_book,
                                                  size: 70,
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          book.title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          book.author,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${book.price.toStringAsFixed(0)} TL',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                addToCart(book),
                                            child: const Text(
                                              'Sepete Ekle',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
