import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import '../widgets/error_display.dart';

class InventoryDialogs {
  /// Diálogo solo para EDITAR producto (sin sección de lote).
  /// No crea lotes nuevos, solo actualiza los datos del producto vía PATCH.
  static Future<void> showEditProduct(BuildContext context,
      AlmacenController controller,
      {required Map<String, dynamic> prod}) async {
    final pId = prod['productoId']?.toString();
    if (pId == null || pId.isEmpty) return;

    Map<String, dynamic> fullProd = Map<String, dynamic>.from(prod);
    try {
      final detail = await ApiService.getProductByIdentifier(pId);
      if (detail != null) fullProd = detail;
    } catch (_) {}

    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    double foundPrice = 0.0;
    for (final f in ['precioPorUnidad', 'precioVenta', 'precio_venta', 'precio', 'pvp', 'precio_unidad', 'precioUnidad']) {
      final val = fullProd[f];
      if (val != null) {
        final pVal = double.tryParse(val.toString()) ?? 0.0;
        if (pVal > 0) { foundPrice = pVal; break; }
      }
    }

    final codigoCtrl = TextEditingController(text: fullProd['codigoBarras']?.toString() ?? '');
    final nombreCtrl = TextEditingController(text: fullProd['nombre']?.toString() ?? '');
    final nombreGenericoCtrl = TextEditingController(text: fullProd['nombreGenerico']?.toString() ?? '');
    final concentracionCtrl = TextEditingController(text: fullProd['concentracion']?.toString() ?? '');
    final descCtrl = TextEditingController(text: fullProd['descripcion']?.toString() ?? '');
    final precioCtrl = TextEditingController(text: foundPrice > 0 ? foundPrice.toStringAsFixed(2) : '');
    String? catId = fullProd['categoriaId']?.toString();
    String? presId = fullProd['presentacionId']?.toString();
    String? currentImageUrl = fullProd['imagenUrl']?.toString();
    String? casaId;
    if (fullProd['casasId'] != null && (fullProd['casasId'] as List).isNotEmpty) {
      casaId = fullProd['casasId'][0]?.toString();
    }
    XFile? selectedImage;

    final fnCodigo = FocusNode();
    final fnNombre = FocusNode();
    final fnNombreGenerico = FocusNode();
    final fnConcentracion = FocusNode();
    final fnDesc = FocusNode();
    final fnPrecio = FocusNode();

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          Future<void> handleEditSave() async {
            if (!formKey.currentState!.validate()) return;
            final pId = prod['productoId']?.toString();
            if (pId == null || pId.isEmpty) return;
            try {
              final Map<String, dynamic> prodData = {};
              if (codigoCtrl.text.trim().isNotEmpty) prodData['codigoBarras'] = codigoCtrl.text.trim();
              if (nombreCtrl.text.trim().isNotEmpty) prodData['nombre'] = nombreCtrl.text.trim();
              if (nombreGenericoCtrl.text.trim().isNotEmpty) prodData['nombreGenerico'] = nombreGenericoCtrl.text.trim();
              if (concentracionCtrl.text.trim().isNotEmpty) prodData['concentracion'] = concentracionCtrl.text.trim();
              if (descCtrl.text.trim().isNotEmpty) prodData['descripcion'] = descCtrl.text.trim();
              if (catId != null) prodData['categoriaId'] = catId;
              if (presId != null) prodData['presentacionId'] = presId;
              if (casaId != null) prodData['casas'] = [casaId];
              if (precioCtrl.text.trim().isNotEmpty) prodData['precioPorUnidad'] = double.tryParse(precioCtrl.text.replaceAll(',', '.')) ?? 0.0;
              await controller.saveProduct(
                  isEdit: true, productId: pId, data: prodData, image: selectedImage);
              Navigator.pop(dialogCtx);
              ErrorDisplay.successSnackBar(context: context, message: 'Producto actualizado correctamente');
              controller.fetchProducts(isRefresh: true);
            } catch (e) {
              final errMsg = ErrorDisplay.cleanMessage(e);
              if (context.mounted) {
                ErrorDisplay.dialog(context: context, message: errMsg, title: 'Error al guardar');
              }
            }
          }

          return StatefulBuilder(
            builder: (ctx, setDialogState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: 600,
                  decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppTheme.ayanamiBlue, AppTheme.ayanamiBlue.withValues(alpha: 0.8)]),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 18),
                            const Text('Editar Medicamento',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                            const Spacer(),
                            IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(dialogCtx)),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                          child: Form(
                            key: formKey,
                            child: Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(color: AppTheme.ayanamiBlue.withValues(alpha: 0.12)),
                              ),
                              color: Theme.of(context).cardTheme.color,
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _subHeader(Icons.inventory_2_outlined, 'DATOS DEL PRODUCTO'),
                                    const SizedBox(height: 16),
                                    Center(
                                      child: _buildImagePicker(context, currentImageUrl, selectedImage,
                                          (img) => setDialogState(() => selectedImage = img)),
                                    ),
                                    const SizedBox(height: 20),
                                    _premiumField(context, 'Código de Barras *', codigoCtrl, Icons.qr_code_scanner_rounded,
                                        req: true, focusNode: fnCodigo, textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => fnNombre.requestFocus()),
                                    _premiumField(context, 'Nombre Comercial *', nombreCtrl, Icons.medication_rounded,
                                        req: true, focusNode: fnNombre, textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => fnNombreGenerico.requestFocus()),
                                    _premiumField(context, 'Nombre Genérico *', nombreGenericoCtrl, Icons.biotech_rounded,
                                        req: true, focusNode: fnNombreGenerico, textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => fnConcentracion.requestFocus()),
                                    _premiumField(context, 'Concentración *', concentracionCtrl, Icons.science_rounded,
                                        req: true, focusNode: fnConcentracion, textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => fnDesc.requestFocus()),
                                    _premiumField(context, 'Descripción / Notas *', descCtrl, Icons.notes_rounded,
                                        req: true, maxLines: 2, focusNode: fnDesc, textInputAction: TextInputAction.next,
                                        onFieldSubmitted: (_) => fnPrecio.requestFocus()),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _premiumDropdown(context, 'Categoría *', catId,
                                              controller.categorias, 'categoriaId', 'nombre',
                                              (v) => setDialogState(() => catId = v),
                                              controller: controller, setDialogState: setDialogState),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _premiumDropdown(context, 'Presentación *', presId,
                                              controller.presentaciones, 'presentacionId', 'nombre',
                                              (v) => setDialogState(() => presId = v),
                                              controller: controller, setDialogState: setDialogState),
                                        ),
                                      ],
                                    ),
                                    _premiumDropdown(context, 'Casa Farmacéutica *', casaId,
                                        controller.casas, 'casaId', 'nombre',
                                        (v) => setDialogState(() => casaId = v),
                                        controller: controller, setDialogState: setDialogState),
                                    _premiumField(context, 'Precio de Venta *', precioCtrl, Icons.sell_rounded,
                                        req: true, keyboard: TextInputType.number,
                                        focusNode: fnPrecio, textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => handleEditSave()),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                                onPressed: () => Navigator.pop(dialogCtx),
                                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                                child: const Text('CANCELAR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.ayanamiBlue, foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 8, shadowColor: AppTheme.ayanamiBlue.withValues(alpha: 0.4)),
                              onPressed: handleEditSave,
                              child: const Text('GUARDAR CAMBIOS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      fnCodigo.dispose();
      fnNombre.dispose();
      fnNombreGenerico.dispose();
      fnConcentracion.dispose();
      fnDesc.dispose();
      fnPrecio.dispose();
    }
  }

  static Future<void> showAddEditProduct(BuildContext context,
      AlmacenController controller, LotesController lotesCtrl,
      {Map<String, dynamic>? prod,
      bool isNewBatchOnly = false,
      Map<String, dynamic>? prefillBatch}) async {
    final bool isEdit = prod != null && !isNewBatchOnly;
    final bool isBatchOnlyEdit = prefillBatch != null;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // ---------- Compute initial values synchronously ----------
    String stockVal = '';
    String precioCompraVal = '';
    String batchNameVal = '';
    String? batchId;
    DateTime? expiryDate;

    // Aggressive nuclear price search (ignores zeros)
    double foundPrice = 0.0;
    final List<String> priceFields = [
      'precioPorUnidad',
      'precioVenta',
      'precio_venta',
      'precio',
      'pvp',
      'precio_unidad',
      'precioUnidad'
    ];
    if (prod != null) {
      for (var f in priceFields) {
        final val = prod[f];
        if (val != null) {
          final pVal = double.tryParse(val.toString()) ?? 0.0;
          if (pVal > 0) {
            foundPrice = pVal;
            break;
          }
        }
      }
    }
    if (foundPrice == 0 && prefillBatch != null) {
      for (var f in priceFields) {
        final val = prefillBatch[f];
        if (val != null) {
          final pVal = double.tryParse(val.toString()) ?? 0.0;
          if (pVal > 0) {
            foundPrice = pVal;
            break;
          }
        }
      }
    }

    if (isBatchOnlyEdit) {
      stockVal = prefillBatch['cantidadDisponible']?.toString() ?? '0';
      precioCompraVal =
          (prefillBatch['costoCompra'] ?? prefillBatch['costoDeCompra'])
                  ?.toString() ??
              '';
      batchNameVal = prefillBatch['nombreLote'] ?? '';
      batchId = prefillBatch['loteId'];
      // Try all possible date field names
      final rawDate = prefillBatch['fechaDeVencimiento'] ??
          prefillBatch['fechaVencimiento'] ??
          prefillBatch['fecha_vencimiento'] ??
          prefillBatch['expiryDate'] ??
          prefillBatch['expiry_date'];
      if (rawDate != null) expiryDate = DateTime.tryParse(rawDate.toString());
      expiryDate ??= DateTime.now().add(const Duration(days: 365));
    } else if (prod == null) {
      // New product: sensible defaults
      expiryDate = null;
    }
    // For existing products: expiryDate stays null until loaded async below

    final codigo = TextEditingController(
        text: prod?['codigoBarras']?.toString() ?? prefillBatch?['codigoBarras']?.toString() ?? '');
    final nombre = TextEditingController(
        text: prod?['nombre']?.toString() ?? prefillBatch?['nombre']?.toString() ?? '');
    final nombreGenerico = TextEditingController(
        text: prod?['nombreGenerico']?.toString() ?? prefillBatch?['nombreGenerico']?.toString() ?? '');
    final concentracion = TextEditingController(
        text: prod?['concentracion']?.toString() ?? prefillBatch?['concentracion']?.toString() ?? '');
    final desc = TextEditingController(
        text: prod?['descripcion']?.toString() ?? prefillBatch?['descripcion']?.toString() ?? '');
    final precio = TextEditingController(
        text: foundPrice > 0 ? foundPrice.toString() : '');
    final precioCompra = TextEditingController(text: precioCompraVal);
    final batchName = TextEditingController(text: batchNameVal);
    final stock = TextEditingController(text: stockVal);
    XFile? selectedImage;
    String? currentImageUrl = prod?['imagenUrl']?.toString() ?? prefillBatch?['imagenUrl']?.toString();

    String? catId = prod?['categoriaId']?.toString() ?? prefillBatch?['categoriaId']?.toString();
    String? presId = prod?['presentacionId']?.toString() ?? prefillBatch?['presentacionId']?.toString();
    String? provId;
    String? casaId;
    if (prod != null &&
        prod['proveedoresId'] != null &&
        (prod['proveedoresId'] as List).isNotEmpty) {
      provId = prod['proveedoresId'][0]?.toString();
    } else if (prod != null && prod['proveedorId'] != null) {
      provId = prod['proveedorId']?.toString();
    } else if (prefillBatch != null && prefillBatch['proveedoresId'] != null &&
        (prefillBatch['proveedoresId'] as List).isNotEmpty) {
      provId = prefillBatch['proveedoresId'][0]?.toString();
    } else if (prefillBatch != null && prefillBatch['proveedorId'] != null) {
      provId = prefillBatch['proveedorId']?.toString();
    }
    if (prod != null &&
        prod['casasId'] != null &&
        (prod['casasId'] as List).isNotEmpty) {
      casaId = prod['casasId'][0]?.toString();
    } else if (prefillBatch != null && prefillBatch['casasId'] != null &&
        (prefillBatch['casasId'] as List).isNotEmpty) {
      casaId = prefillBatch['casasId'][0]?.toString();
    }

    // ---------- Focus nodes for keyboard navigation ----------
    final fnCodigo = FocusNode();
    final fnNombre = FocusNode();
    final fnNombreGenerico = FocusNode();
    final fnConcentracion = FocusNode();
    final fnDesc = FocusNode();
    final fnBatchName = FocusNode();
    final fnPrecio = FocusNode();
    final fnPrecioCompra = FocusNode();
    final fnStock = FocusNode();

    // ---------- Show dialog IMMEDIATELY ----------
    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return StatefulBuilder(
            builder: (ctx, setDialogState) {
            // Load batch data async the FIRST TIME (when expiryDate is still null for an edit)
            if (prod != null && !isBatchOnlyEdit && expiryDate == null) {
              expiryDate = DateTime(9999); // sentinel to prevent multiple calls
              ApiService.getBatchesByProduct(prod['productoId'].toString())
                  .then((batches) {
                if (batches.isNotEmpty) {
                  final firstB = batches.first;
                  final pc = (firstB['costoCompra'] ??
                          firstB['costoDeCompra'] ??
                          firstB['precioCompra'] ??
                          firstB['costo'] ??
                          '')
                      .toString();
                  final st = (firstB['cantidadDisponible'] ??
                          firstB['stock'] ??
                          firstB['cantidad'] ??
                          firstB['existencia'] ??
                          prod['cantidadDisponible'] ??
                          prod['stock'] ??
                          '0')
                      .toString();
                  final rawDate = firstB['fechaDeVencimiento'] ??
                      firstB['fechaVencimiento'] ??
                      firstB['fecha_vencimiento'] ??
                      firstB['expiryDate'] ??
                      firstB['expiry_date'];
                  DateTime? loadedDate = rawDate != null
                      ? DateTime.tryParse(rawDate.toString())
                      : null;
                  loadedDate ??= DateTime.now().add(const Duration(days: 365));

                  double bPrice = 0.0;
                  if (foundPrice == 0) {
                    bPrice = double.tryParse(firstB['precioPorUnidad']?.toString() ?? '0') ?? 0.0;
                  }

                  setDialogState(() {
                    precioCompra.text = pc;
                    stock.text = st;
                    expiryDate = loadedDate;
                    if (bPrice > 0) precio.text = bPrice.toString();
                  });
                } else {
                  // No batches: set safe default
                  setDialogState(() {
                    expiryDate = DateTime.now().add(const Duration(days: 365));
                  });
                }
              }).catchError((_) {
                setDialogState(() {
                  expiryDate = DateTime.now().add(const Duration(days: 365));
                });
              });
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 900,
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPremiumHeader(isEdit, isNewBatchOnly, isBatchOnlyEdit,
                        dialogCtx, context),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              if (isBatchOnlyEdit || isNewBatchOnly) ...[
                                _buildProductInfoHeader(nombre.text, codigo.text),
                                const SizedBox(height: 16),
                                _buildBatchCardSection(
                                    ctx,
                                    controller,
                                    setDialogState,
                                    isBatchOnlyEdit,
                                    provId,
                                    precio,
                                    precioCompra,
                                    stock,
                                    batchName,
                                    expiryDate,
                                    (v) => setDialogState(() => provId = v),
                                    (v) =>
                                        setDialogState(() => expiryDate = v),
                                    fnBatchName: fnBatchName,
                                    fnPrecio: fnPrecio,
                                    fnPrecioCompra: fnPrecioCompra,
                                    fnStock: fnStock),
                              ] else ...[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProductCardSection(
                      context,
                      isEdit,
                      isNewBatchOnly || isBatchOnlyEdit,
                      codigo,
                      nombre,
                      nombreGenerico,
                      concentracion,
                      desc,
                      catId,
                      presId,
                      casaId,
                      controller,
                      currentImageUrl,
                      selectedImage,
                      (img) => setDialogState(() => selectedImage = img),
                      (v) => setDialogState(() => catId = v),
                      (v) => setDialogState(() => presId = v),
                      (v) => setDialogState(() => casaId = v),
                      setDialogState: setDialogState,
                      fnCodigo: fnCodigo,
                      fnNombre: fnNombre,
                      fnNombreGenerico: fnNombreGenerico,
                      fnConcentracion: fnConcentracion,
                      fnDesc: fnDesc),
                                  const SizedBox(width: 24),
                                  _buildBatchCardSection(
                                      ctx,
                                      controller,
                                      setDialogState,
                                      isBatchOnlyEdit,
                                      provId,
                                      precio,
                                      precioCompra,
                                      stock,
                                      batchName,
                                      expiryDate,
                                      (v) => setDialogState(() => provId = v),
                                      (v) =>
                                          setDialogState(() => expiryDate = v),
                                      fnBatchName: fnBatchName,
                                      fnPrecio: fnPrecio,
                                      fnPrecioCompra: fnPrecioCompra,
                                      fnStock: fnStock),
                                ],
                              ),
                              ],
                              const SizedBox(height: 32),
                              _buildPremiumActions(
                                  context,
                                  dialogCtx,
                                  controller,
                                  lotesCtrl,
                                  formKey,
                                  isEdit,
                                  isNewBatchOnly,
                                  isBatchOnlyEdit,
                                  provId,
                                  casaId,
                                  codigo,
                                  nombre,
                                  nombreGenerico,
                                  concentracion,
                                  desc,
                                  catId,
                                  presId,
                                  precio,
                                  precioCompra,
                                  stock,
                                  batchName,
                                  prod,
                                  batchId,
                                  expiryDate,
                                  selectedImage,
                                  prefillBatch?['productoId']?.toString() ?? prefillBatch?['productId']?.toString()),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    } finally {
      fnCodigo.dispose();
      fnNombre.dispose();
      fnNombreGenerico.dispose();
      fnConcentracion.dispose();
      fnDesc.dispose();
      fnBatchName.dispose();
      fnPrecio.dispose();
      fnPrecioCompra.dispose();
      fnStock.dispose();
    }
  }

  static Widget _buildPremiumHeader(bool isEdit, bool isNewBatch,
      bool isBatchEdit, BuildContext dialogCtx, BuildContext context) {
    String title = 'Nuevo Medicamento';
    if (isBatchEdit) {
      title = 'Editar Lote';
    } else if (isNewBatch)
      title = 'Añadir Lote a Producto';
    else if (isEdit) title = 'Editar Medicamento';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 8, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Icon(isEdit || isBatchEdit ? Icons.edit_rounded : Icons.add_box_rounded,
              color: AppTheme.ayanamiBlue, size: 22),
          const SizedBox(width: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const Spacer(),
          IconButton(
              icon: Icon(Icons.close_rounded, color: Colors.grey.shade500),
              onPressed: () => Navigator.pop(dialogCtx)),
        ],
      ),
    );
  }

  static Widget _buildProductCardSection(
      BuildContext context,
      bool isEdit,
      bool readOnly,
      TextEditingController codigo,
      TextEditingController nombre,
      TextEditingController nombreGenerico,
      TextEditingController concentracion,
      TextEditingController desc,
      String? catId,
      String? presId,
      String? casaId,
      AlmacenController controller,
      String? currentImageUrl,
      XFile? selectedImage,
      Function(XFile?) onImage,
      Function(String?) onCat,
      Function(String?) onPres,
      Function(String?) onCasa,
      {StateSetter? setDialogState,
      FocusNode? fnCodigo, FocusNode? fnNombre, FocusNode? fnNombreGenerico,
      FocusNode? fnConcentracion, FocusNode? fnDesc}) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _subHeader(Icons.inventory_2_outlined, 'DATOS DEL PRODUCTO'),
              const SizedBox(height: 20),
              _formRow([
                _formField(context, 'Código de Barras *', codigo, Icons.qr_code_scanner_rounded,
                    req: true, readOnly: readOnly,
                    focusNode: fnCodigo, textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => fnNombre?.requestFocus()),
                _formField(context, 'Nombre Comercial *', nombre, Icons.medication_rounded,
                    req: true, readOnly: readOnly,
                    focusNode: fnNombre, textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => fnNombreGenerico?.requestFocus()),
              ]),
              _formRow([
                _formField(context, 'Nombre Genérico *', nombreGenerico, Icons.biotech_rounded,
                    req: true, readOnly: readOnly,
                    focusNode: fnNombreGenerico, textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => fnConcentracion?.requestFocus()),
                _formField(context, 'Concentración *', concentracion, Icons.science_rounded,
                    req: true, readOnly: readOnly,
                    focusNode: fnConcentracion, textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => fnDesc?.requestFocus()),
              ]),
              _formField(context, 'Descripción / Notas *', desc, Icons.notes_rounded,
                  maxLines: 2, req: true, readOnly: readOnly,
                  focusNode: fnDesc, textInputAction: TextInputAction.done),
              const SizedBox(height: 8),
              _sectionDivider(context),
              const SizedBox(height: 12),
              Row(children: [
                Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.category_rounded, size: 14, color: AppTheme.ayanamiBlue)),
                const SizedBox(width: 10),
                const Text('CLASIFICACIÓN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 12),
              _formRow([
                _premiumDropdown(context, 'Categoría *', catId, controller.categorias, 'categoriaId', 'nombre', onCat,
                    readOnly: readOnly, controller: readOnly ? null : controller, setDialogState: setDialogState),
                _premiumDropdown(context, 'Presentación *', presId, controller.presentaciones, 'presentacionId', 'nombre', onPres,
                    readOnly: readOnly, controller: readOnly ? null : controller, setDialogState: setDialogState),
              ]),
              _premiumDropdown(context, 'Casa Farmacéutica *', casaId, controller.casas, 'casaId', 'nombre', onCasa,
                  controller: readOnly ? null : controller, setDialogState: setDialogState),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  width: 140, height: 140,
                  decoration: BoxDecoration(
                    color: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.1)),
                  ),
                  child: _buildImagePicker(context, currentImageUrl, selectedImage, onImage),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildProductInfoHeader(String productName, String productCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.ayanamiBlue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.ayanamiBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_rounded, color: AppTheme.ayanamiBlue, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(productName.isNotEmpty ? productName : 'Producto',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                if (productCode.isNotEmpty)
                  Text('Código: $productCode',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildBatchCardSection(
      BuildContext context,
      AlmacenController controller,
      StateSetter setDialogState,
      bool isBatchEdit,
      String? provId,
      TextEditingController precio,
      TextEditingController precioCompra,
      TextEditingController stock,
      TextEditingController batchName,
      DateTime? expiryDate,
      Function(String?) onProv,
      Function(DateTime?) onDate,
      {FocusNode? fnBatchName, FocusNode? fnPrecio, FocusNode? fnPrecioCompra, FocusNode? fnStock}) {
    final batchContent = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.greenMetal.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _subHeader(Icons.layers_outlined, 'DETALLES DEL LOTE'),
            const SizedBox(height: 20),
            _formField(context, 'Nombre/ID del Lote *', batchName, Icons.tag_rounded,
                req: true, focusNode: fnBatchName, textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => fnPrecio?.requestFocus()),
            if (!isBatchEdit)
              _premiumDropdown(context, 'Proveedor *', provId, controller.proveedores, 'proveedorId', 'nombre', onProv,
                  controller: controller, setDialogState: setDialogState),
            const SizedBox(height: 8),
            _sectionDivider(context),
            const SizedBox(height: 12),
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.greenMetal.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.attach_money_rounded, size: 14, color: AppTheme.greenMetal)),
              const SizedBox(width: 10),
              const Text('PRECIOS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 12),
            _formRow([
              _formField(context, 'Precio Venta *', precio, Icons.sell_rounded,
                  req: true, keyboard: TextInputType.number,
                  focusNode: fnPrecio, textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => fnPrecioCompra?.requestFocus()),
              _formField(context, 'Costo Compra *', precioCompra, Icons.shopping_cart_rounded,
                  req: true, keyboard: TextInputType.number,
                  focusNode: fnPrecioCompra, textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => fnStock?.requestFocus()),
            ]),
            const SizedBox(height: 8),
            _sectionDivider(context),
            const SizedBox(height: 12),
            Row(children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.reiOrangeRed.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.inventory_rounded, size: 14, color: AppTheme.reiOrangeRed)),
              const SizedBox(width: 10),
              const Text('INVENTARIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 12),
            _formRow([
              _formField(context, 'Stock *', stock, Icons.warehouse_rounded,
                  req: true, keyboard: TextInputType.number,
                  focusNode: fnStock, textInputAction: TextInputAction.done),
              _premiumDatePicker(context, setDialogState, expiryDate, onDate),
            ]),
          ],
        ),
      ),
    );
    if (isBatchEdit) return batchContent;
    return Expanded(child: batchContent);
  }

  static Widget _subHeader(IconData icon, String title) {
    return Row(
      children: [
        Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: AppTheme.ayanamiBlue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: AppTheme.ayanamiBlue)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.blueGrey, letterSpacing: 1.2)),
      ],
    );
  }

  static Widget _sectionDivider(BuildContext context) {
    return Divider(height: 1, color: Colors.grey.withValues(alpha: 0.08));
  }

  static Widget _formRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: children[i]),
        ],
      ]),
    );
  }

  static Widget _formField(BuildContext context, String label, TextEditingController ctrl, IconData icon,
      {bool req = false, bool readOnly = false, int maxLines = 1, TextInputType keyboard = TextInputType.text,
      FocusNode? focusNode, TextInputAction? textInputAction, ValueChanged<String>? onFieldSubmitted}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl, readOnly: readOnly, maxLines: maxLines,
        keyboardType: keyboard,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: [
          if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true))
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          if (label.toLowerCase().contains('nombre'))
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
        ],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label, isDense: true,
          prefixIcon: Padding(padding: const EdgeInsets.only(right: 8),
            child: Icon(icon, color: AppTheme.ayanamiBlue.withValues(alpha: 0.6), size: 18)),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          filled: true,
          fillColor: readOnly ? Colors.grey.withValues(alpha: 0.04) : AppTheme.ayanamiBlue.withValues(alpha: 0.03),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.ayanamiBlue, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          floatingLabelStyle: const TextStyle(color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w700, fontSize: 12),
        ),
        validator: (v) {
          if (req && (v == null || v.trim().isEmpty)) return 'Requerido';
          if (label.toLowerCase().contains('código') || label.toLowerCase().contains('codigo')) {
            if (v != null && v.isNotEmpty) {
              if (RegExp(r'[^0-9]').hasMatch(v)) return 'Solo dígitos';
              if (v.length < 8 || v.length > 14) return 'Debe tener 8-14 dígitos';
            }
          }
          if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true)) {
            if (v != null && v.isNotEmpty) {
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null) return 'Ingrese un número válido';
              if (val < 0) return 'No se permiten valores negativos';
              if (label.toLowerCase().contains('precio') || label.toLowerCase().contains('costo')) {
                if (val == 0) return 'Debe ser mayor a 0';
              }
              if (label.toLowerCase().contains('stock') || label.toLowerCase().contains('cantidad')) {
                if (!val.isFinite || val != val.roundToDouble()) return 'Debe ser un número entero';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  static Widget _premiumField(BuildContext context, String label,
      TextEditingController ctrl, IconData icon,
      {bool req = false,
      bool readOnly = false,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text,
      FocusNode? focusNode,
      TextInputAction? textInputAction,
      ValueChanged<String>? onFieldSubmitted}) {
    
    // Configurar restricciones de entrada automáticas
    List<TextInputFormatter> formatters = [];
    if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true)) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')));
    }
    if (label.toLowerCase().contains('nombre') || label.toLowerCase().contains('categoría') || label.toLowerCase().contains('presentación')) {
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboard,
        focusNode: focusNode,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        inputFormatters: formatters,
        autovalidateMode: AutovalidateMode.onUserInteraction, // Validación inmediata
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              color: AppTheme.ayanamiBlue.withValues(alpha: 0.7), size: 20),
          filled: true,
          fillColor: readOnly
              ? Colors.grey.withValues(alpha: 0.05)
              : AppTheme.ayanamiBlue.withValues(alpha: 0.03),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.transparent)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  const BorderSide(color: AppTheme.ayanamiBlue, width: 2)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.reiOrangeRed, width: 1)),
          floatingLabelStyle: const TextStyle(
              color: AppTheme.ayanamiBlue, fontWeight: FontWeight.bold),
        ),
        validator: (v) {
          if (req && (v == null || v.trim().isEmpty)) return 'Este campo es requerido';
          if (label.toLowerCase().contains('código') || label.toLowerCase().contains('codigo')) {
            if (v != null && v.isNotEmpty) {
              if (RegExp(r'[^0-9]').hasMatch(v)) return 'Solo dígitos';
              if (v.length < 8 || v.length > 14) return 'Debe tener 8-14 dígitos';
            }
          }
          if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true)) {
            if (v != null && v.isNotEmpty) {
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null) return 'Ingrese un número válido';
              if (val < 0) return 'No se permiten valores negativos';
              if (label.toLowerCase().contains('precio') || label.toLowerCase().contains('costo')) {
                if (val == 0) return 'Debe ser mayor a 0';
              }
              if (label.toLowerCase().contains('stock') || label.toLowerCase().contains('cantidad')) {
                if (!val.isFinite || val != val.roundToDouble()) return 'Debe ser un número entero';
              }
            }
          }
          return null;
        },
      ),
    );
  }

  static Widget _premiumDropdown(
      BuildContext context,
      String label,
      String? value,
      List items,
      String idK,
      String labelK,
      Function(String?) onChanged,
      {bool readOnly = false,
      AlmacenController? controller,
      StateSetter? setDialogState}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: IgnorePointer(
        ignoring: readOnly,
        child: (() {
          final tipo = idK == 'categoriaId' ? 'categoria' : idK == 'presentacionId' ? 'presentacion' : idK == 'casaId' ? 'casa' : 'proveedor';

          final rawMapped = items.asMap().entries.map((entry) {
            final idx = entry.key;
            final i = entry.value;
            final map = Map<String, dynamic>.from(i);
            final id = (map[idK]?.toString().isNotEmpty == true)
                ? map[idK].toString()
                : (map['id']?.toString().isNotEmpty == true)
                    ? map['id'].toString()
                    : (map['proveedorId']?.toString().isNotEmpty == true)
                        ? map['proveedorId'].toString()
                        : '_idx_$idx';
            final labelText = (map[labelK] ??
                    map['nombre'] ??
                    map['nombreProveedor'] ??
                    map['razonSocial'] ??
                    'N/A')
                .toString();
            return {'id': id, 'label': labelText};
          }).toList();

          final seen = <String>{};
          final List<Map<String, String>> mappedItems = [];
          for (var it in rawMapped) {
            if (!seen.contains(it['id'])) {
              seen.add(it['id']!);
              mappedItems.add(it);
            }
          }

          final bool valueExists = mappedItems.any((it) => it['id'] == value);
          final String? safeValue = valueExists ? value : null;

          const createNewId = '__CREATE_NEW__';

          return DropdownButtonFormField<String>(
            value: safeValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: readOnly
                  ? Colors.grey.withValues(alpha: 0.05)
                  : AppTheme.ayanamiBlue.withValues(alpha: 0.03),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
            items: [
              DropdownMenuItem<String>(
                value: createNewId,
                child: Row(children: [
                  Icon(Icons.add_circle_rounded, color: AppTheme.greenMetal, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Nueva ${tipo == 'categoria' ? 'categoría' : tipo == 'presentacion' ? 'presentación' : tipo == 'casa' ? 'casa' : 'proveedor'}',
                    style: const TextStyle(color: AppTheme.greenMetal, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ]),
              ),
              if (mappedItems.isNotEmpty) ...[
                const DropdownMenuItem<String>(
                  enabled: false,
                  value: '__DIVIDER__',
                  child: Divider(height: 1),
                ),
                ...mappedItems.map((it) => DropdownMenuItem(
                      value: it['id'],
                      child: Text(it['label']!, overflow: TextOverflow.ellipsis),
                    )),
              ] else
                const DropdownMenuItem<String>(
                  enabled: false,
                  value: '__EMPTY__',
                  child: Text('(Sin registrar)', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12)),
                ),
            ],
            onChanged: (v) {
              if (v == createNewId) {
                _showQuickCreateDialog(context, tipo, controller, setDialogState).then((newId) {
                  if (newId != null) onChanged(newId);
                });
              } else if (v != '__DIVIDER__') {
                onChanged(v);
              }
            },
            validator: (v) => (v == null || v == createNewId || v == '__DIVIDER__') ? 'Requerido' : null,
          );
        })(),
      ),
    );
  }

  /// Returns the newly created item's ID (or null if cancelled/failed).
  static Future<String?> _showQuickCreateDialog(
    BuildContext parentContext,
    String tipo,
    AlmacenController? controller,
    StateSetter? setDialogState,
  ) async {
    String? createdId;
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    final fnNombre = FocusNode();
    final fnDesc = FocusNode();
    final fnTel = FocusNode();
    final fnEmail = FocusNode();

    final tipoLabel = tipo == 'categoria' ? 'categoría' : tipo == 'presentacion' ? 'presentación' : tipo == 'casa' ? 'casa' : 'proveedor';

    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
        Future<void> doQuickSave(StateSetter setSt, BuildContext dialogCtx) async {
          if (!formKey.currentState!.validate()) return;
          setSt(() => isCreating = true);
          try {
            Map<String, dynamic> data = {
              'nombre': nameCtrl.text.trim(),
            };
            if (tipo == 'proveedor') {
              if (descCtrl.text.trim().isNotEmpty) data['direccion'] = descCtrl.text.trim();
              if (telCtrl.text.trim().isNotEmpty) data['telefono'] = telCtrl.text.trim();
              if (emailCtrl.text.trim().isNotEmpty) data['email'] = emailCtrl.text.trim();
            } else if (tipo == 'casa') {
              data['paisDeOrigen'] = descCtrl.text.trim();
            } else {
              if (descCtrl.text.trim().isNotEmpty) data['descripcion'] = descCtrl.text.trim();
            }
            Map<String, dynamic> res;
            if (tipo == 'categoria') {
              res = await ApiService.createCategory(data);
              createdId = (res['data']?['categoriaId'] ?? res['data']?['id'])?.toString();
              await controller?.fetchCategorias();
            } else if (tipo == 'presentacion') {
              res = await ApiService.createPresentation(data);
              createdId = (res['data']?['presentacionId'] ?? res['data']?['id'])?.toString();
              await controller?.fetchPresentaciones();
            } else if (tipo == 'casa') {
              res = await ApiService.createHouse(data);
              createdId = (res['data']?['casaId'] ?? res['data']?['id'])?.toString();
              await controller?.fetchCasas();
            } else {
              res = await ApiService.createSupplier(data);
              createdId = (res['data']?['proveedorId'] ?? res['data']?['id'])?.toString();
              await controller?.fetchProveedores();
            }
            if (Navigator.of(dialogCtx).canPop()) {
              Navigator.pop(dialogCtx);
              ErrorDisplay.successSnackBar(context: parentContext, message: '$tipoLabel registrada correctamente');
            }
            setDialogState?.call(() {});
          } catch (e) {
            final errMsg = ErrorDisplay.cleanMessage(e);
            if (Navigator.of(dialogCtx).canPop()) {
              ErrorDisplay.snackBar(context: parentContext, message: errMsg, title: 'Error');
            }
          } finally {
            setSt(() => isCreating = false);
          }
        }

        return StatefulBuilder(
          builder: (ctx2, setSt) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                width: 450,
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.greenMetal.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.add_circle_rounded, color: AppTheme.greenMetal, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Text('Nueva $tipoLabel',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                          const Spacer(),
                          IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: isCreating ? null : () => Navigator.pop(ctx2)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: nameCtrl,
                        autofocus: true,
                        focusNode: fnNombre,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => fnDesc.requestFocus(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]')),
                        ],
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Nombre *',
                          prefixIcon: const Icon(Icons.label_rounded, color: AppTheme.ayanamiBlue, size: 20),
                          filled: true,
                          fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        focusNode: fnDesc,
                        textInputAction: tipo == 'proveedor' ? TextInputAction.next : TextInputAction.done,
                        onFieldSubmitted: tipo == 'proveedor'
                            ? (_) => fnTel.requestFocus()
                            : (_) => doQuickSave(setSt, ctx2),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        inputFormatters: tipo == 'casa' ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'))] : [],
                        decoration: InputDecoration(
                          labelText: tipo == 'proveedor' ? 'Dirección *' : tipo == 'casa' ? 'País de Origen *' : 'Descripción *',
                          prefixIcon: Icon(
                              tipo == 'proveedor' ? Icons.location_on_rounded : Icons.description_rounded,
                              color: AppTheme.ayanamiBlue,
                              size: 20),
                          filled: true,
                          fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (tipo == 'casa' && RegExp(r'[0-9]').hasMatch(v)) return 'Solo se permiten letras';
                          return null;
                        },
                      ),
                      if (tipo == 'proveedor') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telCtrl,
                          keyboardType: TextInputType.phone,
                          focusNode: fnTel,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => fnEmail.requestFocus(),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.ayanamiBlue, size: 20),
                            filled: true,
                            fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          focusNode: fnEmail,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => doQuickSave(setSt, ctx2),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Email (opcional)',
                            prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.ayanamiBlue, size: 20),
                            filled: true,
                            fillColor: AppTheme.ayanamiBlue.withValues(alpha: 0.03),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) {
                              return 'Email inválido';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: isCreating ? null : () => Navigator.pop(ctx2),
                              child: const Text('CANCELAR',
                                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.greenMetal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            onPressed: isCreating ? null : () => doQuickSave(setSt, ctx2),
                            child: isCreating
                                ? const SizedBox(
                                    width: 18, height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('REGISTRAR',
                                    style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    fnNombre.dispose();
    fnDesc.dispose();
    fnTel.dispose();
    fnEmail.dispose();
    return createdId;
  }

  static Widget _premiumDatePicker(BuildContext context,
      StateSetter setDialogState, DateTime? date, Function(DateTime?) onDate) {
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate =
        DateTime.now().add(const Duration(days: 365 * 10));
    final DateTime safeInitial =
        (date == null || date.year >= 9999 || date.isAfter(lastDate))
            ? DateTime.now().add(const Duration(days: 365))
            : (date.isBefore(firstDate) ? firstDate : date);
    final bool isLoading = date != null && date.year == 9999;
    return GestureDetector(
      onTap: isLoading ? null : () async {
        try {
          final picked = await showDatePicker(
            context: context, initialDate: safeInitial,
            firstDate: firstDate, lastDate: lastDate,
            helpText: 'Fecha de Vencimiento',
            confirmText: 'ACEPTAR', cancelText: 'CANCELAR',
          );
          if (picked != null) onDate(picked);
        } catch (e) { debugPrint('DatePicker error: $e'); }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isLoading ? Colors.grey.withValues(alpha: 0.04) : AppTheme.ayanamiBlue.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date == null ? AppTheme.reiOrangeRed.withValues(alpha: 0.5) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Fecha Venc. *',
            prefixIcon: Padding(padding: const EdgeInsets.only(right: 8),
              child: Icon(Icons.calendar_month_rounded, color: AppTheme.ayanamiBlue.withValues(alpha: 0.6), size: 18)),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            floatingLabelStyle: const TextStyle(color: AppTheme.ayanamiBlue, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          child: Row(children: [
            Icon(isLoading ? Icons.hourglass_top : Icons.event_available_rounded,
                color: isLoading ? Colors.grey : AppTheme.ayanamiBlue, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(
              isLoading ? 'Cargando...' : date == null
                  ? 'Seleccionar fecha *'
                  : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
              style: TextStyle(
                color: isLoading ? Colors.grey : (date == null ? AppTheme.reiOrangeRed : null),
                fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis)),
            if (!isLoading)
              Icon(Icons.edit_calendar_outlined, color: AppTheme.ayanamiBlue.withValues(alpha: 0.5), size: 16),
          ]),
        ),
      ),
    );
  }

  static Widget _buildPremiumActions(
      BuildContext context,
      BuildContext dialogCtx,
      AlmacenController controller,
      LotesController lotesCtrl,
      GlobalKey<FormState> formKey,
      bool isEdit,
      bool isNewBatch,
      bool isBatchEdit,
      String? provId,
      String? casaId,
      TextEditingController codigo,
      TextEditingController nombre,
      TextEditingController nombreGenerico,
      TextEditingController concentracion,
      TextEditingController desc,
      String? catId,
      String? presId,
      TextEditingController precio,
      TextEditingController precioCompra,
      TextEditingController stock,
      TextEditingController batchName,
      Map<String, dynamic>? prod,
      String? batchId,
      DateTime? expiryDate,
      XFile? selectedImage,
      [String? batchProductId]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            child: const Text('CANCELAR',
                style: TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.bold))),
        const SizedBox(width: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.ayanamiBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: AppTheme.ayanamiBlue.withValues(alpha: 0.4)),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            if (expiryDate == null || expiryDate.year >= 9999) {
              ErrorDisplay.snackBar(context: context, message: 'Selecciona una fecha de vencimiento');
              return;
            }

            // Validate dropdowns that are local vars (not caught by formKey)
            if (!isEdit && !isBatchEdit) {
              if (provId == null) {
                ErrorDisplay.snackBar(context: context, message: 'Debes seleccionar un proveedor para el lote');
                return;
              }
            }
            if (!isEdit && !isNewBatch && !isBatchEdit) {
              if (catId == null) {
                ErrorDisplay.snackBar(context: context, message: 'Debes seleccionar una categoría');
                return;
              }
              if (presId == null) {
                ErrorDisplay.snackBar(context: context, message: 'Debes seleccionar una presentación');
                return;
              }
              if (false) {
                ErrorDisplay.snackBar(context: context, message: 'Debes seleccionar un proveedor');
                return;
              }
              if (casaId == null) {
                ErrorDisplay.snackBar(context: context, message: 'Debes seleccionar una casa farmacéutica');
                return;
              }
            }

            final pParsed =
                double.tryParse(precio.text.replaceAll(',', '.')) ?? 0.0;
            final pcParsed =
                double.tryParse(precioCompra.text.replaceAll(',', '.')) ?? 0.0;
            final stockParsed = int.tryParse(stock.text.trim()) ?? 0;
            // Send full ISO date with UTC timezone (NestJS/Sequelize standard)
            final expStr =
                DateTime.utc(expiryDate.year, expiryDate.month, expiryDate.day)
                    .toIso8601String();

            try {
              String? finalProdId = prod?['productoId']?.toString();

                if (!isNewBatch && !isBatchEdit) {
                final prodData = <String, dynamic>{};
                if (codigo.text.trim().isNotEmpty) prodData['codigoBarras'] = codigo.text.trim();
                if (nombre.text.trim().isNotEmpty) prodData['nombre'] = nombre.text.trim();
                if (nombreGenerico.text.trim().isNotEmpty) prodData['nombreGenerico'] = nombreGenerico.text.trim();
                if (concentracion.text.trim().isNotEmpty) prodData['concentracion'] = concentracion.text.trim();
                if (desc.text.trim().isNotEmpty) prodData['descripcion'] = desc.text.trim();
                if (catId != null) prodData['categoriaId'] = catId;
                if (presId != null) prodData['presentacionId'] = presId;
                if (pParsed > 0) prodData['precioPorUnidad'] = pParsed;
                prodData['proveedores'] = [
                  {'proveedorId': provId, 'costo': pcParsed}
                ];
                if (casaId != null) prodData['casas'] = [casaId];
                final result = await controller.saveProduct(
                    isEdit: isEdit, productId: finalProdId, data: prodData, image: selectedImage);
                // result is already the product data object, not the full API response
                finalProdId = result['productoId']?.toString() ?? result['id']?.toString();
              }

              if (isBatchEdit && batchId != null) {
                final Map<String, dynamic> batchData = {
                  'nombreLote': batchName.text.trim(),
                  'cantidadDisponible': stockParsed,
                };
                if (pcParsed > 0) batchData['costoDeCompra'] = pcParsed;
                if (expiryDate != null) {
                  batchData['fechaDeVencimiento'] =
                      DateTime.utc(expiryDate.year, expiryDate.month, expiryDate.day)
                          .toIso8601String();
                }
                await lotesCtrl.updateBatch(batchId, batchData);
                if (pParsed > 0 && batchProductId != null) {
                  await controller.saveProduct(
                      isEdit: true,
                      productId: batchProductId,
                      data: {'precioPorUnidad': pParsed});
                }
              } else {
                final Map<String, dynamic> batchData = {
                  'nombreLote': batchName.text.trim(),
                  'fechaDeVencimiento': expStr,
                  'cantidadDisponible': stockParsed,
                  'costoDeCompra': pcParsed,
                };
                if (finalProdId != null) batchData['productoId'] = finalProdId;
                await lotesCtrl.createBatch(batchData);
              }
              // Close dialog AFTER successful save
              Navigator.pop(dialogCtx);
              ErrorDisplay.successSnackBar(context: context, message: '¡Guardado con éxito!');
              controller.fetchProducts(isRefresh: true);
            } catch (e) {
              final errMsg = ErrorDisplay.cleanMessage(e);
              if (context.mounted) {
                ErrorDisplay.dialog(context: context, message: errMsg, title: 'Error al guardar');
              }
            }
          },
          child: Text(isEdit || isBatchEdit ? 'GUARDAR CAMBIOS' : 'REGISTRAR',
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
      ],
    );
  }

  static Widget _buildImagePicker(BuildContext context, String? currentUrl,
      XFile? selected, Function(XFile?) onImage) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final picker = ImagePicker();
          final img = await picker.pickImage(source: ImageSource.gallery);
          if (img != null) onImage(img);
        },
        child: kIsWeb && selected != null
            ? _WebImagePreview(selected: selected, currentUrl: currentUrl)
            : Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: AppTheme.ayanamiBlue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.ayanamiBlue.withValues(alpha: 0.2), width: 2),
                  image: selected != null
                      ? DecorationImage(
                          image: FileImage(File(selected.path)),
                          fit: BoxFit.cover)
                      : (currentUrl != null && currentUrl.isNotEmpty)
                          ? DecorationImage(
                              image: NetworkImage(currentUrl),
                              fit: BoxFit.cover)
                          : null,
                ),
                child: (selected == null &&
                        (currentUrl == null || currentUrl.isEmpty))
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_rounded,
                              color:
                                  AppTheme.ayanamiBlue.withValues(alpha: 0.5),
                              size: 40),
                          const SizedBox(height: 8),
                          const Text('Añadir foto',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.ayanamiBlue,
                                  fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Stack(
                        children: [
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.edit,
                                  size: 16, color: AppTheme.ayanamiBlue),
                            ),
                          ),
                          Positioned(
                            left: 4,
                            top: 4,
                            child: GestureDetector(
                              onTap: () => onImage(null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }
}

class _WebImagePreview extends StatefulWidget {
  final XFile selected;
  final String? currentUrl;
  const _WebImagePreview({required this.selected, this.currentUrl});

  @override
  State<_WebImagePreview> createState() => _WebImagePreviewState();
}

class _WebImagePreviewState extends State<_WebImagePreview> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  Future<void> _loadBytes() async {
    final bytes = await widget.selected.readAsBytes();
    if (mounted) setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _bytes != null;
    final hasUrl =
        widget.currentUrl != null && widget.currentUrl!.isNotEmpty;

    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: AppTheme.ayanamiBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.ayanamiBlue.withValues(alpha: 0.2), width: 2),
        image: hasImage
            ? DecorationImage(image: MemoryImage(_bytes!), fit: BoxFit.cover)
            : hasUrl
                ? DecorationImage(
                    image: NetworkImage(widget.currentUrl!),
                    fit: BoxFit.cover)
                : null,
      ),
      child: (!hasImage && !hasUrl)
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo_rounded,
                    color: AppTheme.ayanamiBlue.withValues(alpha: 0.5), size: 40),
                const SizedBox(height: 8),
                const Text('Añadir foto',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.ayanamiBlue,
                        fontWeight: FontWeight.bold)),
              ],
            )
          : Stack(
              children: [
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.edit,
                        size: 16, color: AppTheme.ayanamiBlue),
                  ),
                )
              ],
            ),
    );
  }
}
