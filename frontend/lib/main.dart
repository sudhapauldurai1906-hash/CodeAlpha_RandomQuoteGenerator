import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

const String baseUrl = "http://localhost:2000";

// ── Palette ──────────────────────────────────────────────
const Color kBg = Color(0xFF0A0A0F);
const Color kSurface = Color(0xFF13131A);
const Color kCard = Color(0xFF1C1C28);
const Color kAccent = Color(0xFFE8FF47); // electric lime
const Color kAccent2 = Color(0xFFFF4771); // hot pink
const Color kText = Color(0xFFF0EFE8);
const Color kMuted = Color(0xFF6B6B7A);
const Color kBorder = Color(0xFF2A2A38);

class Quote {
  int? id;
  String text;
  String author;

  Quote({this.id, required this.text, required this.author});

  factory Quote.fromJson(Map<String, dynamic> json) => Quote(
        id: json['id'],
        text: json['text'],
        author: json['author'],
      );
}

void main() => runApp(const QuoteApp());

class QuoteApp extends StatelessWidget {
  const QuoteApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: kBg,
          colorScheme: const ColorScheme.dark(
            primary: kAccent,
            secondary: kAccent2,
            surface: kSurface,
          ),
        ),
        home: const QuoteHome(),
      );
}

// ── Main Screen ───────────────────────────────────────────
class QuoteHome extends StatefulWidget {
  const QuoteHome({super.key});

  @override
  State<QuoteHome> createState() => _QuoteHomeState();
}

class _QuoteHomeState extends State<QuoteHome>
    with TickerProviderStateMixin {
  List<Quote> quotes = [];
  int currentIndex = 0;
  bool _flipping = false;

  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _flipAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    fetchQuotes();
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future fetchQuotes() async {
    final res = await http.get(Uri.parse("$baseUrl/quotes"));
    final data = jsonDecode(res.body);
    setState(() {
      quotes = data['result'].map<Quote>((e) => Quote.fromJson(e)).toList();
    });
    _fadeCtrl.forward(from: 0);
  }

  Future<void> _animateToIndex(int newIndex) async {
    if (_flipping) return;
    setState(() => _flipping = true);
    await _flipCtrl.forward(from: 0);
    setState(() {
      currentIndex = newIndex;
      _flipping = false;
    });
    _flipCtrl.reverse();
    _fadeCtrl.forward(from: 0);
  }

  void nextQuote() {
    if (currentIndex < quotes.length - 1) _animateToIndex(currentIndex + 1);
  }

  void prevQuote() {
    if (currentIndex > 0) _animateToIndex(currentIndex - 1);
  }

  // ── Dialogs ──────────────────────────────────────────────
  void _showQuoteDialog({Quote? existing}) {
    final textCtrl =
        TextEditingController(text: existing?.text ?? '');
    final authorCtrl =
        TextEditingController(text: existing?.author ?? '');
    final isEdit = existing != null;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        return SlideTransition(
          position: slide,
          child: FadeTransition(
            opacity: anim,
            child: Center(
              child: _QuoteDialog(
                isEdit: isEdit,
                textCtrl: textCtrl,
                authorCtrl: authorCtrl,
                onSave: () async {
                  if (isEdit) {
                    await http.put(
                      Uri.parse("$baseUrl/updateQuote/${existing!.id}"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "text": textCtrl.text,
                        "author": authorCtrl.text,
                      }),
                    );
                  } else {
                    await http.post(
                      Uri.parse("$baseUrl/addQuote"),
                      headers: {"Content-Type": "application/json"},
                      body: jsonEncode({
                        "text": textCtrl.text,
                        "author": authorCtrl.text,
                      }),
                    );
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  fetchQuotes();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void deleteQuote() async {
    await http.delete(
        Uri.parse("$baseUrl/deleteQuote/${quotes[currentIndex].id}"));
    if (currentIndex > 0) currentIndex--;
    fetchQuotes();
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          // ── Decorative background blobs ─────────────────
          Positioned(
            top: -80,
            right: -60,
            child: _GlowBlob(color: kAccent.withOpacity(0.07), size: 280),
          ),
          Positioned(
            bottom: 100,
            left: -80,
            child: _GlowBlob(color: kAccent2.withOpacity(0.06), size: 320),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QUOTEBOOK',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              letterSpacing: 4.5,
                              color: kAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Your\nWisdom\nLibrary.',
                            style: TextStyle(
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              color: kText,
                              letterSpacing: -1.2,
                            ),
                          ),
                        ],
                      ),
                      // Add button
                      GestureDetector(
                        onTap: () => _showQuoteDialog(),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.add_rounded,
                              color: kBg, size: 28),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // ── Counter strip ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: kAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              quotes.isEmpty
                                  ? '—'
                                  : '${currentIndex + 1} of ${quotes.length}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: kMuted,
                                  letterSpacing: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Quote Card ───────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: quotes.isEmpty
                        ? _EmptyState(onAdd: () => _showQuoteDialog())
                        : AnimatedBuilder(
                            animation: _flipAnim,
                            builder: (_, child) {
                              final angle = _flipAnim.value * pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: child,
                              );
                            },
                            child: FadeTransition(
                              opacity: _fadeAnim,
                              child: _QuoteCard(
                                quote: quotes[currentIndex],
                                index: currentIndex,
                                total: quotes.length,
                              ),
                            ),
                          ),
                  ),
                ),

                // ── Navigation & Actions ─────────────────────
                if (quotes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Row(
                      children: [
                        // Prev
                        _NavBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: currentIndex > 0 ? prevQuote : null,
                        ),
                        const SizedBox(width: 12),
                        // Next
                        _NavBtn(
                          icon: Icons.arrow_forward_rounded,
                          onTap: currentIndex < quotes.length - 1
                              ? nextQuote
                              : null,
                        ),
                        const Spacer(),
                        // Edit
                        _ActionBtn(
                          icon: Icons.edit_rounded,
                          label: 'Edit',
                          color: kAccent,
                          onTap: () =>
                              _showQuoteDialog(existing: quotes[currentIndex]),
                        ),
                        const SizedBox(width: 10),
                        // Delete
                        _ActionBtn(
                          icon: Icons.delete_outline_rounded,
                          label: 'Delete',
                          color: kAccent2,
                          onTap: deleteQuote,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quote Card ─────────────────────────────────────────────
class _QuoteCard extends StatelessWidget {
  final Quote quote;
  final int index;
  final int total;

  const _QuoteCard(
      {required this.quote, required this.index, required this.total});

  Color _accentForIndex(int i) {
    final colors = [
      kAccent,
      kAccent2,
      const Color(0xFF47C8FF),
      const Color(0xFFBB47FF),
      const Color(0xFFFF9F47),
    ];
    return colors[i % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForIndex(index);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.08),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Top accent stripe
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28)),
              ),
            ),
          ),

          // Large decorative quote mark
          Positioned(
            top: 24,
            right: 24,
            child: Text(
              '"',
              style: TextStyle(
                fontSize: 120,
                height: 0.8,
                color: accent.withOpacity(0.1),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Index tag
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Quote text
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      quote.text,
                      style: const TextStyle(
                        fontSize: 26,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: kText,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Divider + Author
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 2,
                      color: accent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        quote.author.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2.4,
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dialog ─────────────────────────────────────────────────
class _QuoteDialog extends StatelessWidget {
  final bool isEdit;
  final TextEditingController textCtrl;
  final TextEditingController authorCtrl;
  final VoidCallback onSave;

  const _QuoteDialog({
    required this.isEdit,
    required this.textCtrl,
    required this.authorCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: kAccent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(
                  isEdit ? 'EDIT QUOTE' : 'NEW QUOTE',
                  style: const TextStyle(
                    fontSize: 11,
                    letterSpacing: 3,
                    color: kAccent,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StyledField(
                controller: textCtrl, hint: 'Type the quote...', maxLines: 4),
            const SizedBox(height: 14),
            _StyledField(controller: authorCtrl, hint: 'Author name'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: kBorder),
                      ),
                      alignment: Alignment.center,
                      child: const Text('Cancel',
                          style: TextStyle(color: kMuted, fontSize: 14)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onSave,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: kAccent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        isEdit ? 'Save' : 'Add',
                        style: const TextStyle(
                          color: kBg,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _StyledField(
      {required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: kText, fontSize: 15),
        cursorColor: kAccent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: kMuted, fontSize: 15),
          filled: true,
          fillColor: kSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kAccent, width: 1.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}

// ── Nav Button ─────────────────────────────────────────────
class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? kSurface : kSurface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? kBorder : kBorder.withOpacity(0.4),
          ),
        ),
        child: Icon(icon,
            color: active ? kText : kMuted.withOpacity(0.4), size: 22),
      ),
    );
  }
}

// ── Action Button ──────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
}

// ── Empty State ────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
              ),
              child: const Icon(Icons.format_quote_rounded,
                  color: kMuted, size: 36),
            ),
            const SizedBox(height: 20),
            const Text('No quotes yet',
                style: TextStyle(
                    color: kText, fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Add your first one to get started',
                style: TextStyle(color: kMuted, fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: kAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Add Quote',
                    style: TextStyle(
                        color: kBg,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      );
}

// ── Glow Blob ──────────────────────────────────────────────
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );
}