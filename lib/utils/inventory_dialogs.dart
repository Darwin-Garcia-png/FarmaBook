import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../controllers/almacen_controller.dart';
import '../controllers/lotes_controller.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

class InventoryDialogs {
  static Future<void> showAddEditProduct(BuildContext context,
      AlmacenController controller, LotesController lotesCtrl,
      {Map<String, dynamic>? prod,
      bool isNewBatchOnly = false,
      Map<String, dynamic>? prefillBatch}) async {
    final bool isEdit = prod != null && !isNewBatchOnly;
    final bool isBatchOnlyEdit = prefillBatch != null;
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    // ---------- Compute initial values synchronously ----------
    String stockVal = '0';
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
      expiryDate = DateTime.now().add(const Duration(days: 365));
    }
    // For existing products: expiryDate stays null until loaded async below

    final codigo = TextEditingController(text: prod?['codigoBarras'] ?? '');
    final nombre = TextEditingController(text: prod?['nombre'] ?? '');
    final desc = TextEditingController(text: prod?['descripcion'] ?? '');
    final precio = TextEditingController(
        text: foundPrice > 0 ? foundPrice.toString() : '');
    final precioCompra = TextEditingController(text: precioCompraVal);
    final batchName = TextEditingController(text: batchNameVal);
    final stock = TextEditingController(text: stockVal);
    XFile? selectedImage;
    String? currentImageUrl = prod?['imagenUrl']?.toString();

    String? catId = prod?['categoriaId']?.toString();
    String? presId = prod?['presentacionId']?.toString();
    String? provId;
    if (prod != null &&
        prod['proveedoresId'] != null &&
        (prod['proveedoresId'] as List).isNotEmpty) {
      provId = prod['proveedoresId'][0]?.toString();
    } else if (prod != null && prod['proveedorId'] != null) {
      provId = prod['proveedorId']?.toString();
    }

    // ---------- Show dialog IMMEDIATELY (no await before this) ----------
    showDialog(
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProductCardSection(
                      context,
                      isEdit,
                      isNewBatchOnly || isBatchOnlyEdit,
                      codigo,
                      nombre,
                      desc,
                      catId,
                      presId,
                      controller,
                      currentImageUrl,
                      selectedImage,
                      (img) => setDialogState(() => selectedImage = img),
                      (v) => setDialogState(() => catId = v),
                      (v) => setDialogState(() => presId = v),
                      setDialogState: setDialogState),
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
                                          setDialogState(() => expiryDate = v)),
                                ],
                              ),
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
                                  codigo,
                                  nombre,
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
                                  selectedImage),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        AppTheme.ayanamiBlue,
        AppTheme.ayanamiBlue.withOpacity(0.8)
      ])),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(
                isEdit || isBatchEdit
                    ? Icons.edit_rounded
                    : Icons.add_box_rounded,
                color: Colors.white,
                size: 28),
          ),
          const SizedBox(width: 18),
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5)),
          const Spacer(),
          IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
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
      TextEditingController desc,
      String? catId,
      String? presId,
      AlmacenController controller,
      String? currentImageUrl,
      XFile? selectedImage,
      Function(XFile?) onImage,
      Function(String?) onCat,
      Function(String?) onPres,
      {StateSetter? setDialogState}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subHeader(Icons.inventory_2_outlined, 'DATOS DEL PRODUCTO'),
          const SizedBox(height: 16),
          _buildImagePicker(context, currentImageUrl, selectedImage, onImage),
          const SizedBox(height: 20),
          _premiumField(context, 'Código de Barras *', codigo,
              Icons.qr_code_scanner_rounded,
              req: true, readOnly: readOnly),
          _premiumField(
              context, 'Nombre Comercial *', nombre, Icons.medication_rounded,
              req: true, readOnly: readOnly),
          _premiumField(
              context, 'Descripción / Notas', desc, Icons.notes_rounded,
              maxLines: 2, readOnly: readOnly),
          Row(
            children: [
              Expanded(
                  child: _premiumDropdown(context, 'Categoría', catId,
                      controller.categorias, 'categoriaId', 'nombre', onCat,
                      readOnly: readOnly,
                      controller: readOnly ? null : controller,
                      setDialogState: setDialogState)),
              const SizedBox(width: 16),
              Expanded(
                  child: _premiumDropdown(
                      context,
                      'Presentación',
                      presId,
                      controller.presentaciones,
                      'presentacionId',
                      'nombre',
                      onPres,
                      readOnly: readOnly,
                      controller: readOnly ? null : controller,
                      setDialogState: setDialogState)),
            ],
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
      Function(DateTime?) onDate) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _subHeader(Icons.layers_outlined, 'DETALLES DEL LOTE'),
          const SizedBox(height: 16),
          _premiumField(
              context, 'Nombre/ID del Lote', batchName, Icons.tag_rounded,
              req: true),
          if (!isBatchEdit)
            _premiumDropdown(context, 'Proveedor', provId,
                controller.proveedores, 'proveedorId', 'nombre', onProv,
                controller: controller,
                setDialogState: setDialogState),
          Row(
            children: [
              Expanded(
                  child: _premiumField(
                      context, 'Precio Venta *', precio, Icons.sell_rounded,
                      req: true, keyboard: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(
                  child: _premiumField(context, 'Costo Compra *', precioCompra,
                      Icons.shopping_cart_rounded,
                      req: true, keyboard: TextInputType.number)),
            ],
          ),
          Row(
            children: [
              Expanded(
                  child: _premiumField(context, 'Stock Cantidad *', stock,
                      Icons.warehouse_rounded,
                      req: true, keyboard: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(
                  child: _premiumDatePicker(
                      context, setDialogState, expiryDate, onDate)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _subHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.ayanamiBlue),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.blueGrey,
                letterSpacing: 1.2)),
      ],
    );
  }

  static Widget _premiumField(BuildContext context, String label,
      TextEditingController ctrl, IconData icon,
      {bool req = false,
      bool readOnly = false,
      int maxLines = 1,
      TextInputType keyboard = TextInputType.text}) {
    
    // Configurar restricciones de entrada automáticas
    List<TextInputFormatter> formatters = [];
    if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true)) {
      // Solo números y un punto decimal
      formatters.add(FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')));
    } else if (label.toLowerCase().contains('nombre') || label.toLowerCase().contains('categoría') || label.toLowerCase().contains('presentación')) {
      // Evitar números en campos de nombre puro (opcional, depende de la lógica de negocio)
      // Pero el usuario pidió: "no se puedan colocar numeros donde solo deben de ir letras"
      // formatters.add(FilteringTextInputFormatter.deny(RegExp(r'[0-9]'))); 
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly,
        maxLines: maxLines,
        keyboardType: keyboard,
        inputFormatters: formatters,
        autovalidateMode: AutovalidateMode.onUserInteraction, // Validación inmediata
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon,
              color: AppTheme.ayanamiBlue.withOpacity(0.7), size: 20),
          filled: true,
          fillColor: readOnly
              ? Colors.grey.withOpacity(0.05)
              : AppTheme.ayanamiBlue.withOpacity(0.03),
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
          
          if (keyboard == TextInputType.number || keyboard == const TextInputType.numberWithOptions(decimal: true)) {
            if (v != null && v.isNotEmpty) {
              final val = double.tryParse(v.replaceAll(',', '.'));
              if (val == null) return 'Ingrese un número válido';
              if (val < 0) return 'No se permiten valores negativos';
            }
          }

          // Validación de letras donde solo van letras (si el usuario lo pidió explícitamente para nombres)
          if (label.toLowerCase().contains('nombre') && !label.toLowerCase().contains('lote') && !label.toLowerCase().contains('comercial')) {
             if (v != null && RegExp(r'[0-9]').hasMatch(v)) {
               return 'No se permiten números en este campo';
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
          final tipo = idK == 'categoriaId' ? 'categoria' : idK == 'presentacionId' ? 'presentacion' : 'proveedor';

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
                  ? Colors.grey.withOpacity(0.05)
                  : AppTheme.ayanamiBlue.withOpacity(0.03),
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
                    'Nueva ${tipo == 'categoria' ? 'categoría' : tipo == 'presentacion' ? 'presentación' : 'proveedor'}',
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
                _showQuickCreateDialog(context, tipo, controller, setDialogState);
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

  static Future<void> _showQuickCreateDialog(
    BuildContext parentContext,
    String tipo,
    AlmacenController? controller,
    StateSetter? setDialogState,
  ) async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isCreating = false;

    final tipoLabel = tipo == 'categoria' ? 'categoría' : tipo == 'presentacion' ? 'presentación' : 'proveedor';

    await showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (ctx) {
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
                              color: AppTheme.greenMetal.withOpacity(0.1),
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Nombre *',
                          prefixIcon: const Icon(Icons.label_rounded, color: AppTheme.ayanamiBlue, size: 20),
                          filled: true,
                          fillColor: AppTheme.ayanamiBlue.withOpacity(0.03),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          if (RegExp(r'[0-9]').hasMatch(v)) return 'No se permiten números';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: tipo == 'proveedor' ? 'Dirección (opcional)' : 'Descripción (opcional)',
                          prefixIcon: Icon(
                              tipo == 'proveedor' ? Icons.location_on_rounded : Icons.description_rounded,
                              color: AppTheme.ayanamiBlue,
                              size: 20),
                          filled: true,
                          fillColor: AppTheme.ayanamiBlue.withOpacity(0.03),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      if (tipo == 'proveedor') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telCtrl,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Teléfono (opcional)',
                            prefixIcon: const Icon(Icons.phone_rounded, color: AppTheme.ayanamiBlue, size: 20),
                            filled: true,
                            fillColor: AppTheme.ayanamiBlue.withOpacity(0.03),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: 'Email (opcional)',
                            prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.ayanamiBlue, size: 20),
                            filled: true,
                            fillColor: AppTheme.ayanamiBlue.withOpacity(0.03),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none),
                          ),
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
                            onPressed: isCreating
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setSt(() => isCreating = true);

                                    try {
                                      Map<String, dynamic> data = {
                                        'nombre': nameCtrl.text.trim(),
                                      };

                                      if (tipo == 'proveedor') {
                                        if (descCtrl.text.trim().isNotEmpty) {
                                          data['direccion'] = descCtrl.text.trim();
                                        }
                                        if (telCtrl.text.trim().isNotEmpty) {
                                          data['telefono'] = telCtrl.text.trim();
                                        }
                                        if (emailCtrl.text.trim().isNotEmpty) {
                                          data['email'] = emailCtrl.text.trim();
                                        }
                                      } else {
                                        if (descCtrl.text.trim().isNotEmpty) {
                                          data['descripcion'] = descCtrl.text.trim();
                                        }
                                      }

                                      if (tipo == 'categoria') {
                                        await ApiService.createCategory(data);
                                      } else if (tipo == 'presentacion') {
                                        await ApiService.createPresentation(data);
                                      } else {
                                        await ApiService.createSupplier(data);
                                      }

                                      if (Navigator.of(ctx2).canPop()) {
                                        Navigator.pop(ctx2);
                                        ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                                            content: Text('$tipoLabel registrada correctamente'),
                                            backgroundColor: AppTheme.greenMetal));
                                      }

                                      if (tipo == 'categoria') {
                                        controller?.fetchCategorias();
                                      } else if (tipo == 'presentacion') {
                                        controller?.fetchPresentaciones();
                                      } else {
                                        controller?.fetchProveedores();
                                      }
                                      setDialogState?.call(() {});
                                    } catch (e) {
                                      String errMsg = e.toString();
                                      try {
                                        final serverMsg = (e as dynamic)?.response?.data?['message'] ??
                                            (e as dynamic)?.response?.data?['error'];
                                        if (serverMsg != null) errMsg = serverMsg.toString();
                                      } catch (_) {}
                                      if (Navigator.of(ctx2).canPop()) {
                                        ScaffoldMessenger.of(parentContext).showSnackBar(SnackBar(
                                            content: Text('Error: $errMsg'),
                                            backgroundColor: AppTheme.reiOrangeRed));
                                      }
                                    } finally {
                                      setSt(() => isCreating = false);
                                    }
                                  },
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
  }

  static Widget _premiumDatePicker(BuildContext context,
      StateSetter setDialogState, DateTime? date, Function(DateTime?) onDate) {
    final DateTime firstDate = DateTime(2000);
    final DateTime lastDate =
        DateTime.now().add(const Duration(days: 365 * 10));
    // Clamp initialDate safely (handles sentinel DateTime(9999) and null)
    final DateTime safeInitial =
        (date == null || date.year >= 9999 || date.isAfter(lastDate))
            ? DateTime.now().add(const Duration(days: 365))
            : (date.isBefore(firstDate) ? firstDate : date);
    final bool isLoading = date != null && date.year == 9999;
    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              try {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: safeInitial,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  helpText: 'Fecha de Vencimiento',
                  confirmText: 'ACEPTAR',
                  cancelText: 'CANCELAR',
                );
                if (picked != null) onDate(picked);
              } catch (e) {
                debugPrint('DatePicker error: $e');
              }
            },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isLoading
              ? Colors.grey.withOpacity(0.05)
              : AppTheme.ayanamiBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: date == null
                ? AppTheme.reiOrangeRed.withOpacity(0.5)
                : AppTheme.ayanamiBlue.withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
                isLoading ? Icons.hourglass_top : Icons.event_available_rounded,
                color: isLoading ? Colors.grey : AppTheme.ayanamiBlue,
                size: 20),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isLoading
                    ? 'Cargando fecha...'
                    : date == null
                        ? 'Seleccionar fecha *'
                        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                style: TextStyle(
                  color: isLoading
                      ? Colors.grey
                      : (date == null ? AppTheme.reiOrangeRed : null),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isLoading)
              Icon(Icons.edit_calendar_outlined,
                  color: AppTheme.ayanamiBlue.withOpacity(0.5), size: 16),
          ],
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
      TextEditingController codigo,
      TextEditingController nombre,
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
      XFile? selectedImage) {
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
              shadowColor: AppTheme.ayanamiBlue.withOpacity(0.4)),
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            if (expiryDate == null || expiryDate.year >= 9999) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content:
                      Text('Por favor, selecciona una fecha de vencimiento')));
              return;
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

              // CLOUDINARY UPLOAD IF NEW IMAGE SELECTED
              String? uploadedUrl;
              if (selectedImage != null) {
                uploadedUrl = await ApiService.uploadImage(selectedImage);
              }

              if (!isNewBatch && !isBatchEdit) {
                final prodData = {
                  'codigoBarras': codigo.text.trim(),
                  'nombre': nombre.text.trim(),
                  'descripcion': desc.text.trim(),
                  'categoriaId': catId,
                  'presentacionId': presId,
                  'precioPorUnidad': pParsed,
                };
                if (uploadedUrl != null) prodData['imagenUrl'] = uploadedUrl;
                if (!isEdit) prodData['proveedorId'] = provId;
                final res = await controller.saveProduct(
                    isEdit: isEdit, productId: finalProdId, data: prodData);
                finalProdId = res.data['data']['productoId']?.toString();
              }

              final Map<String, dynamic> batchData = {
                'nombreLote': batchName.text.trim(),
                'fechaDeVencimiento': expStr,
                'cantidadDisponible': stockParsed,
                'costoDeCompra':
                    pcParsed, // Correct field name (costoCompra rejected)
              };
              if (isBatchEdit && batchId != null) {
                await lotesCtrl.updateBatch(batchId, batchData);
              } else {
                if (finalProdId != null) batchData['productoId'] = finalProdId;
                await lotesCtrl.createBatch(batchData);
              }
              // Close dialog AFTER successful save
              Navigator.pop(dialogCtx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('¡Guardado con éxito!'),
                  backgroundColor: AppTheme.greenMetal));
              controller.fetchProducts(isRefresh: true);
            } catch (e) {
              String errMsg = e.toString();
              // Try to extract server message from DioException
              try {
                final dioErr = e as dynamic;
                final serverMsg = dioErr?.response?.data?['message'] ??
                    dioErr?.response?.data?['error'];
                if (serverMsg != null) errMsg = serverMsg.toString();
                debugPrint('SERVER ERROR BODY: ${dioErr?.response?.data}');
              } catch (_) {}
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Error: $errMsg'),
                  backgroundColor: AppTheme.reiOrangeRed));
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
                  color: AppTheme.ayanamiBlue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.ayanamiBlue.withOpacity(0.2), width: 2),
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
                                  AppTheme.ayanamiBlue.withOpacity(0.5),
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
                          )
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
        color: AppTheme.ayanamiBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.ayanamiBlue.withOpacity(0.2), width: 2),
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
                    color: AppTheme.ayanamiBlue.withOpacity(0.5), size: 40),
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
