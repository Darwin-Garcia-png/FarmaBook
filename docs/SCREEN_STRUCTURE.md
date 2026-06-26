# Screen Structure Reference — FarmaBook

Guía rápida de la anatomía de cada pantalla para localizar secciones específicas al hacer cambios.

---

## `login_screen.dart` (587 líneas)

```
Scaffold
└── body: Stack
    ├── AnimatedBuilder        → gradient background (#0F2027→#203A43→#2C5364)
    │   └── _buildFloatingIcons() → CustomPaint: 6 iconos médicos flotando
    ├── [Corner glows]         → AnimatedBuilder con radial glow ayanamiBlue
    └── Center
        └── SingleChildScrollView (maxWidth:400)
            └── Column
                ├── _AnimatedLogo          (línea 233)
                │   → assets/images/logo.png (80×80, ClipRRect R20)
                │   → "FarmaBook" (34px w900)
                │   → "Gestión Inteligente" subtítulo (13px, letter-spacing 3)
                │   → Animación flotante (Translation 0→-8→0 px)
                └── _LoginForm             (línea 307)
                    → FadeTransition + SlideTransition (700ms)
                    → GlassContainer (white 0.06, R28)
                    → Form con:
                      ├── _Field("Usuario")      (línea 415)
                      │   → TextFormField + validator
                      │   → AnimatedContainer borde según _focused
                      │   → Enter → salta a Contraseña
                      ├── _Field("Contraseña")   (línea 415)
                      │   → toggle visibilidad (suffix icon)
                      │   → Enter → ejecuta login
                      └── _LoginButton           (línea 519)
                          → MouseRegion + AnimatedScale + AnimatedContainer
                          → Gradiente + sombra
                          → CircularProgressIndicator si isLoading
                          → disabled mientras loading
```

**Métodos clave:**
| Método | Línea | Renderiza |
|--------|-------|-----------|
| `_buildFloatingIcons()` | 177 | `CustomPaint` + `_FloatingIconsPainter` |
| `_AnimatedLogo` | 233 | Logo + título + subtítulo con float animation |
| `_LoginForm` | 307 | Formulario con fade+slide entrance |
| `_Field` | 415 | Input individual con foco animado |
| `_LoginButton` | 519 | Botón con hover scale + loading state |

---

## `dashboard_screen.dart` (639 líneas) — Scaffold principal

```
Scaffold
├── drawer: Drawer
│   └── Container (R32, card color, shadow)
│       └── Column
│           ├── _buildDrawerHeader()           (línea 173)
│           │   → AnimatedEntry(0)
│           │   → Image.asset('assets/images/logo_base.png', 120×120, R16)
│           ├── Expanded
│           │   └── ListView
│           │       ├── AnimatedEntry(0) → _buildDrawerItem(Panel Inicio, 0)    (línea 194)
│           │       ├── AnimatedEntry(1) → _buildDrawerItem(Almacén Central, 1)
│           │       ├── AnimatedEntry(2) → _buildDrawerItem(Punto de Venta, 2)
│           │       ├── [if isDueno] AnimatedEntry(3) → _buildDrawerItem(Gestión de Lotes, 3)
│           │       ├── [if isDueno] AnimatedEntry(4) → _buildDrawerItem(Estadísticas, 4)
│           │       ├── AnimatedEntry(5) → _buildDrawerItem(Manual de Ayuda, 11)
│           │       └── [if isDueno] _buildExpansionCatalogos()   (línea 146)
│           │           → ExpansionTile
│           │           → Casas(5), Categorías(7), Presentaciones(8)
│           │           → Proveedores(9), Usuarios(10)
│           ├── Divider
│           ├── _buildNotifItem()               (línea 301)
│           │   → Consumer<NotificacionesController>
│           │   → ListTile con badge + _showNotifDialog()
│           ├── _buildCreditsItem()             (línea 408)
│           │   → ListTile "Acerca de" → _showCreditsDialog()
│           │     → "FarmaBook v1.0.0"
│           │     → 3 credit rows con avatar
│           └── _buildLogoutItem()              (línea 425)
│               → ListTile → UserSession.clear() → navega /login
└── body: CallbackShortcuts → Focus → Stack
    ├── ParticleBackground (ayanamiBlue, 15 partículas)
    └── RepaintBoundary
        └── _buildScreen()                      (línea 117)
            → switch _controller.selectedIndex:
              0:InicioScreen 1:AlmacenScreen 2:VentasScreen
              3:LotesScreen 4:EstadisticasScreen
              5:CasasScreen 7:CategoriasScreen 8:PresentacionesScreen
              9:ProveedoresScreen 10:UsuariosScreen 11:ManualScreen
```

**Drawer items:** `_buildDrawerItem(icon, title, index)` con `AnimatedContainer` + `HoverScale`.  
**Sub items:** `_buildDrawerSubItem(icon, title, index)` con padding extra.

---

## `inicio_screen.dart` (451 líneas) — Panel de inicio

```
Scaffold
└── body: Stack
    ├── ParticleBackground (opacity 0.08)
    ├── [HEADER] Positioned(top:0)
    │   └── Container(height:80)
    │       ├── IconButton(menu) → abre Scaffold.drawer
    │       ├── Container (pharmacy icon, ayanamiBlue tint)
    │       ├── Text("FARMABOOK")
    │       ├── Spacer
    │       └── IconButton(settings) → push /configuracion
    └── SingleChildScrollView (padding: 40/100/40/60)
        └── Column(crossAxisAlignment:start)
            ├── [GREETING] AnimatedEntry(0) → Row
            │   ├── saludo (Buenos días/tardes/noches según hora)
            │   └── fecha formateada
            ├── [KPIs] Row de 4 _kpi()         (línea 368)
            │   ├── Ingresos (greenMetal, trending_up)
            │   ├── Egresos (reiOrangeRed, trending_down)
            │   ├── Balance (purple, account_balance)
            │   └── Stock (ayanamiBlue, inventory, con progress bar)
            └── [CONTENT] Row
                ├── LEFT (flex:3) → AnimatedEntry(5)
                │   ├── _sectionH("VENTAS RECIENTES")  (línea 357)
                │   │   → 5 items con borde verde
                │   │   → [empty] _emptyCard()
                │   └── _sectionH("PRODUCTOS TOP")
                │       → top 3 con #1 oro, #2 plata, #3 bronce
                │       → progress bars
                └── RIGHT (flex:2) → AnimatedEntry(6)
                    ├── Stock health card (porcentaje + progress 3-colores)
                    ├── _sectionH("ALERTAS")
                    │   → [none] check verde + "Sin alertas activas"
                    │   → [stock] 3 cards borde rojo
                    │   → [expiry] 3 cards borde naranja
                    └── _sectionH("ACCESO RÁPIDO")
                        ├── Ventas + Almacén (todos)
                        └── [if isDueno] Lotes + Stats
```

**Estados:**
| Estado | Render |
|--------|--------|
| `isLoading` | `ShimmerList` (6 items, 100px) |
| `error != null` | `_errorView()` → `ErrorDisplay.fullScreen` con retry |
| `recentSales.empty && topProducts.empty` | `_emptyCard()` |

---

## `almacen_screen.dart` (366 líneas) — Almacén Central

```
Consumer2<AlmacenController, LotesController>
└── Scaffold
    └── appBar: PremiumHeader("Almacén Central", refresh trailing)
    └── body: Column
        ├── _buildHeader()                     (línea 70)
        │   ├── TextField (searchCtrl, hint: buscar nombre/código)
        │   │   └── suffix: search + clear (visible si texto != "")
        │   ├── DropdownButtonFormField (categorías, "Todas las categorías")
        │   ├── _buildLowStockButton()         (línea 264)
        │   │   → ElevatedButton.icon red (activo) / outlined (inactivo)
        │   ├── [if isDueno] SizedBox + _buildAddButton()  (línea 291)
        │   │   → "Nuevo" → InventoryDialogs.showAddEditProduct
        │   ├── _buildDropdown(casaSeleccionada)
        │   ├── _buildDropdown(proveedorSeleccionada)
        │   └── _buildDropdown(presentacionSeleccionada)
        └── _buildMainContent()                (línea 308)
            ├── [loading] → ShimmerList (6 items, 220px)
            ├── [error]   → ErrorDisplay.inline (dismiss)
            ├── [empty]   → "No hay productos encontrados"
            └── [normal]  → Expanded → Stack
                └── GridView.builder (maxCrossAxisExtent:300, aspect:0.58, spacing:24)
                    └── AnimatedEntry(index) → ProductCard(p, controller, lotesCtrl)
                        ╚═══ ProductCard: editar/borrar solo si isDueno
                └── [if isFetchingMore] Positioned bottom → CircularProgressIndicator
```

---

## `ventas_screen.dart` (554 líneas) — Punto de Venta

```
ChangeNotifierProvider<VentasController>.value
└── Scaffold
    └── appBar: PremiumHeader("Punto de Venta", refresh trailing)
    └── body: CallbackShortcuts → Focus(autofocus)
        └── Row
            ├── _buildSidebar()                (línea 151)
            │   → Columna navegación: Vender / Historial / Recibos
            │   → _navButton() con AnimatedContainer selección
            ├── Expanded(flex:5)
            │   └── Consumer<VentasController>
            │       └── AnimatedSwitcher(duration:300ms)
            │           ├── [Vista.search]  → SalesSearchSection + SalesResultsGrid
            │           ├── [Vista.history] → _buildSalesHistoryList()
            │           │   → Loading/Empty/ListView.separated
            │           │   → Cada item: onTap→receipt, cancel button
            │           └── [Vista.receipts] → _buildReceiptsCardsList()
            │               → Loading/Empty/GridView
            │               → _buildReceiptCard(): gradient header, productos, total
            └── CartSection()                  (widget externo, 318 líneas)
                → Container(width:320, R24, shadow)
                → _buildHeader(): "Carrito" + count
                → _buildItemsList(): ListView con qty buttons + subtotal
                → _buildSummarySection():
                  ├── _buildConsumidorField(): nombre + cédula
                  ├── TOTAL + monto
                  └── ElevatedButton "COBRAR" → registra venta + ReceiptDialog
```

**Shortcuts:**
| Tecla | Acción |
|-------|--------|
| `F2` | Enfocar barcode |
| `Escape` | Limpiar búsqueda |
| `Ctrl+Enter` | Cobrar |

**Dialogs:**
- `ReceiptDialog(sale)` → recibo PDF con impresión
- `_confirmCancelSale()` → `AlertDialog` para anular venta

---

## `lotes_screen.dart` (733 líneas) — Gestión de Lotes

```
Consumer2<LotesController, AlmacenController>
└── Scaffold
    └── appBar: PremiumHeader("Gestión de Lotes", "Entrada de Lote" trailing)
    └── body: [if isLoading] ShimmerList
              [else] Column
                ├── _buildMetricsRow()                 (línea 154)
                │   → 3 _buildMetricCard(): Activos / En Riesgo / Vencidos
                │   → HoverScale con borde + sombra coloreada
                ├── _buildSearchBar()                  (línea 199)
                │   → TextField + filter toggle (rojo si filtros activos)
                ├── [if _showFilters] _buildFilterPanel()  (línea 225)
                │   → Dropdown producto + 2 DateRange pickers
                │   → "Aplicar Filtros" + "Limpiar"
                ├── _buildTabs()                       (línea 358)
                │   → TabBar: Activos(N) / Por Vencer(N) / Vencidos(N) / Bajo Stock(N) / Historial(N)
                └── Expanded → Stack
                    └── NotificationListener<ScrollNotification>
                        └── TabBarView (5 tabs)
                            ├── _buildBatchList(activos) → filtrado por _searchQuery
                            ├── _buildBatchList(porVencer)
                            ├── _buildBatchList(vencidos)
                            ├── _buildBatchList(bajoStock)
                            └── _buildArchivedList(historial)
                    └── [if isFetchingMore] Positioned bottom → spinner
```

**Cada batch card** (`_buildBatchCard`, línea 552):
- Banner superior: SALUDABLE / POR VENCER / VENCIDO / BAJO STOCK (coloreado)
- Nombre del lote
- Badges: fecha vencimiento, SKU, EAN
- Stock count (grande, color si < 30)
- Precio (footer, azul)
- [if isDueno] Iconos editar + borrar

**Cada archived card** (`_buildArchivedCard`, línea 440): similar pero con banner "SIN STOCK / VENCIDO / ARCHIVADO", sin editar/borrar.

---

## `estadisticas_screen.dart` (412 líneas) — Estadísticas

```
Scaffold
└── appBar: PremiumHeader("Estadísticas", 3 trailing: PDF, resumen, refresh)
└── [if isLoading] CircularProgressIndicator centrado
    [else] SingleChildScrollView(padding:24)
        └── Column(crossAxisAlignment:start)
            ├── [if error] _errorBanner() → ErrorDisplay.inline dismiss
            ├── _sectionH("RESUMEN DEL DÍA")     (línea 189)
            │   → 4 rows de KPIs (ingresos, ventas, ticket, unidades, hora pico, etc.)
            ├── _sectionH("VENTAS POR HORA")     (línea 223)
            │   → SizedBox(height:220) → BarChart (24 barras, hora pico resaltada)
            ├── _sectionH("RENDIMIENTO MENSUAL") (línea 246)
            │   → 4 rows (ingresos mes, ventas, egresos, balance, margen, etc.)
            ├── [if dailyTrend] _sectionH("TENDENCIA DIARIA") (línea 296)
            │   → SizedBox(height:260) → LineChart (curva + línea promedio + gradiente)
            ├── Row
            │   ├── LEFT (flex:3)
            │   │   ├── _sectionH("TOP PRODUCTOS")
            │   │   └── card → _rankBlock("HOY") / _rankBlock("MES") / _rankBlock("GLOBAL")
            │   └── RIGHT (flex:2)
            │       ├── _sectionH("CATEGORÍAS")
            │       └── PieChart (top 5 + leyenda %)
            └── [if supplierRanking] _sectionH("PROVEEDORES POR COSTO")
                → ranking rows
```

**Charts:** `fl_chart` — `BarChart`, `LineChart`, `PieChart`  
**Dialog:** `_showSummary()` → "Cierre de Caja" con 3 secciones (FINANCIERO, OPERATIVO, CONTEXTO)

---

## `configuracion_screen.dart` (309 líneas) — Ajustes

```
Scaffold
└── appBar: PremiumHeader("Ajustes", hideSettings:true, leading: back arrow)
└── body: Stack
    ├── ParticleBackground (12 partículas)
    └── Center → ConstrainedBox(maxWidth:900)
        └── SingleChildScrollView (padding:40/32)
            └── Column(crossAxisAlignment:start)
                ├── _buildProfileCard()               (línea 259)
                │   → AnimatedEntry(bounce) → GlowEffect → GlassContainer
                │   → Row: icono (100px, R32) + "Farmabook" (estático, 28px)
                ├── AnimatedEntry(1)
                │   → _buildSettingsGroup("MI CUENTA")  (línea 294)
                │   → GlassContainer → ListTile "Información Personal"
                │   → _showMyAccountDialog() (línea 123)
                │     → Dialog sin gradient ni scale
                │     → ID, email, rol, tipo cuenta
                │     → ["Guardar Cambios"] → ApiService.updateUser
                └── [if isDueno] AnimatedEntry(2)
                    → _buildSettingsGroup("GESTIÓN DE EQUIPO")
                    → ListTile "Personal y Roles" → dashboard index 10 (UsuariosScreen)
```

---

## `manual_screen.dart` (416 líneas) — StatelessWidget

```
Scaffold
└── Stack
    ├── [HEADER] Positioned(top:0)
    │   → Container(height:100, 0.95 opacity)
    │   → back arrow + menu_book icon + "MANUAL DE AYUDA"
    └── SingleChildScrollView (padding:40/120/40/60)
        └── Column
            ├── _buildHeader()            (línea 51)
            │   → "MANUAL DE USUARIO" (42px w900) + subtítulo
            ├── GUÍA DE MÓDULOS
            │   → _buildModulesGrid()     (línea 74)
            │   → GridView.count (3 cols, 1.4 aspect, height 1000)
            │   → 9 cards (3 condicionales por rol):
            │     Panel Inicio / Almacén / Ventas
            │     [isDueno] Lotes / Estadísticas / Catálogos
            │     Alertas / Movimientos / Manual
            │   → Cada card: icono, título, descripción, "+" detail
            │   → _showDetail() → AlertDialog con guía completa
            ├── FLUJOS DE TRABAJO
            │   → 4 items (3 condicionales)
            │   → _flujo() con icono + numbered steps
            ├── FAQ
            │   → 8 preguntas (4 condicionales)
            │   → _faq() con "?" + bold pregunta + grey respuesta
            └── RESOLUCIÓN DE ERRORES
                → 8 items (1 condicional)
                → _trouble() con icono rojo + título + solución
```

---

## Otras pantallas (catálogos)

| Archivo | Función | 
|---------|---------|
| `casas_screen.dart` | CRUD Casas farmacéuticas |
| `categorias_screen.dart` | CRUD Categorías (con botón retroceder) |
| `presentaciones_screen.dart` | CRUD Presentaciones |
| `proveedores_screen.dart` | CRUD Proveedores |
| `usuarios_screen.dart` | CRUD Usuarios (creación con asignación de token) |
| `forgot_password_screen.dart` | Recuperar contraseña |
| `reset_password_screen.dart` | Restablecer contraseña |
| `verify_pin_screen.dart` | Verificar PIN |

Todas siguen el mismo patrón: `Scaffold` → `PremiumHeader` + lista/detalle con llamadas a `ApiService`.
