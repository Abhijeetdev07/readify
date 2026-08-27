import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _pdfViewerController;
  PdfTextSearcher? _textSearcher;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int _currentPage = 1;
  int _pageCount = 0;
  bool _hasError = false;
  bool _isLoading = true;
  bool _isDragging = false;
  bool _isSearching = false;
  double? _dragFraction;
  bool _showBadge = false;
  Timer? _hideTimer;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController()
      ..addListener(_onControllerUpdate);

    if (!File(widget.filePath).existsSync()) {
      _hasError = true;
      _isLoading = false;
      _errorMessage = 'The selected file could not be found on this device.';
    }
  }

  void _onControllerUpdate() {
    if (mounted && !_isDragging) {
      final newPage = _pdfViewerController.pageNumber ?? 1;
      final newCount = _pdfViewerController.pageCount;
      if (newPage != _currentPage || newCount != _pageCount) {
        setState(() {
          _currentPage = newPage;
          _pageCount = newCount;
        });
        _triggerBadgeVisibility();
      }
    }
  }

  void _onSearcherUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _textSearcher?.dispose();
    super.dispose();
  }

  void _triggerBadgeVisibility() {
    _hideTimer?.cancel();
    if (!_showBadge && mounted) {
      setState(() {
        _showBadge = true;
      });
    }
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted && !_isDragging) {
        setState(() {
          _showBadge = false;
        });
      }
    });
  }

  void _openSearch() {
    setState(() {
      _isSearching = true;
    });
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    _textSearcher?.resetTextSearch();
    _searchFocusNode.unfocus();
    _triggerBadgeVisibility();
  }

  void _onSearchChanged(String query) {
    if (_textSearcher == null) return;
    if (query.trim().isEmpty) {
      _textSearcher?.resetTextSearch();
    } else {
      _textSearcher?.startTextSearch(query.trim());
    }
  }

  Widget _buildErrorView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Unable to Open PDF',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'The PDF file is corrupted, inaccessible, or cannot be read.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSeek(double localDy, double seekableHeight) {
    if (_pageCount <= 1 || seekableHeight <= 0) return;

    final double fraction = localDy.clamp(0.0, seekableHeight) / seekableHeight;
    final int targetPage =
        (1 + (fraction * (_pageCount - 1))).round().clamp(1, _pageCount);

    setState(() {
      _dragFraction = fraction;
      _currentPage = targetPage;
    });
    _pdfViewerController.goToPage(pageNumber: targetPage);
  }

  String _getMatchCountText() {
    if (!_isSearching ||
        _searchController.text.trim().isEmpty ||
        _textSearcher == null) {
      return '';
    }
    if (_textSearcher!.isSearching) return '...';
    if (!_textSearcher!.hasMatches) return '0/0';
    final idx = _textSearcher!.currentIndex;
    final current = (idx != null) ? (idx + 1) : 1;
    final total = _textSearcher!.matches.length;
    return '$current/$total';
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(RegExp(r'[/\\]')).last;
    final matchCountText = _getMatchCountText();
    final hasSearchMatches = _textSearcher?.hasMatches ?? false;

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: 'Search in document...',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearchChanged,
                )
              : Text(
                  fileName,
                  overflow: TextOverflow.ellipsis,
                ),
          actions: [
            if (!_hasError) ...[
              if (_isSearching) ...[
                if (matchCountText.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Text(
                        matchCountText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                  tooltip: 'Previous match',
                  onPressed: hasSearchMatches
                      ? () => _textSearcher?.goToPrevMatch()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  tooltip: 'Next match',
                  onPressed: hasSearchMatches
                      ? () => _textSearcher?.goToNextMatch()
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close search',
                  onPressed: _closeSearch,
                ),
              ] else ...[
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: 'Search',
                  onPressed: _openSearch,
                ),
              ],
            ],
          ],
        ),
        body: _hasError
            ? _buildErrorView(context)
            : LayoutBuilder(
                builder: (context, constraints) {
                  final double availableHeight = constraints.maxHeight;
                  final double topMargin = 32.0;
                  final double bottomMargin = 32.0;
                  final double thumbHeight = 36.0;
                  final double seekableHeight =
                      (availableHeight - topMargin - bottomMargin - thumbHeight)
                          .clamp(0.0, availableHeight);

                  final double fraction = _isDragging
                      ? (_dragFraction ?? 0.0)
                      : ((_pageCount > 1)
                          ? ((_currentPage - 1) / (_pageCount - 1)).clamp(0.0, 1.0)
                          : 0.0);

                  final double thumbTop = topMargin + (seekableHeight * fraction);

                  return Stack(
                    children: [
                      // PDF Viewer
                      PdfViewer.file(
                        widget.filePath,
                        controller: _pdfViewerController,
                        params: PdfViewerParams(
                          pagePaintCallbacks: [
                            (canvas, pageRect, page) {
                              if (_isSearching &&
                                  _searchController.text.trim().isNotEmpty &&
                                  _textSearcher != null) {
                                _textSearcher!.pageTextMatchPaintCallback(
                                  canvas,
                                  pageRect,
                                  page,
                                );
                              }
                            },
                          ],
                          onViewerReady: (document, controller) {
                            if (mounted) {
                              _textSearcher?.dispose();
                              _textSearcher = PdfTextSearcher(controller)
                                ..addListener(_onSearcherUpdate);

                              setState(() {
                                _pageCount = document.pages.length;
                                _currentPage = controller.pageNumber ?? 1;
                                _isLoading = false;
                                _hasError = false;
                              });
                              _triggerBadgeVisibility();
                            }
                          },
                          errorBannerBuilder:
                              (context, error, stackTrace, documentRef) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _hasError = true;
                                  _isLoading = false;
                                  _errorMessage = error.toString();
                                });
                              }
                            });
                            return const SizedBox.shrink();
                          },
                        ),
                      ),

                      // Loading Indicator
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),

                      // Auto-hiding smooth fast-scroll thumb
                      if (!_isLoading && _pageCount > 1)
                        AnimatedPositioned(
                          duration: _isDragging
                              ? Duration.zero
                              : const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          top: thumbTop,
                          right: 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 250),
                            opacity: (_showBadge || _isDragging) ? 1.0 : 0.0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onVerticalDragStart: (details) {
                                _hideTimer?.cancel();
                                final initialFraction = (_pageCount > 1)
                                    ? ((_currentPage - 1) / (_pageCount - 1)).clamp(0.0, 1.0)
                                    : 0.0;
                                setState(() {
                                  _isDragging = true;
                                  _showBadge = true;
                                  _dragFraction = initialFraction;
                                });
                              },
                              onVerticalDragUpdate: (details) {
                                final appBarHeight =
                                    Scaffold.of(context).appBarMaxHeight ?? 0;
                                final localY = details.globalPosition.dy -
                                    appBarHeight -
                                    topMargin -
                                    (thumbHeight / 2);
                                _onSeek(localY, seekableHeight);
                              },
                              onVerticalDragEnd: (_) {
                                setState(() {
                                  _isDragging = false;
                                  _dragFraction = null;
                                });
                                _triggerBadgeVisibility();
                              },
                              onVerticalDragCancel: () {
                                setState(() {
                                  _isDragging = false;
                                  _dragFraction = null;
                                });
                                _triggerBadgeVisibility();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _isDragging
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.black.withValues(alpha: 0.65),
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(16),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(-1, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.unfold_more_rounded,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_currentPage/$_pageCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
