// ====================================================
// MENULY PDV - Protótipo Interativo (Estilo Risko)
// ====================================================

// ---- DADOS MOCKADOS - ROUPAS ----
const PRODUCTS = [
  { id: 1,  barcode: '7891000100103', name: 'Camiseta Basica Algodao Preta',     category: 'Camisetas',  costPrice: 22.00, salePrice: 49.90,  unit: 'un', size: 'M',  stock: 35, minStock: 10, active: true,  image: 'https://picsum.photos/seed/tshirt1/300/400' },
  { id: 2,  barcode: '7891000200207', name: 'Camiseta Polo Masculina Azul',      category: 'Camisetas',  costPrice: 38.00, salePrice: 89.90,  unit: 'un', size: 'G',  stock: 18, minStock: 8,  active: true,  image: 'https://picsum.photos/seed/polo1/300/400' },
  { id: 3,  barcode: '7891000300301', name: 'Camiseta Estampada Floral',         category: 'Camisetas',  costPrice: 28.00, salePrice: 59.90,  unit: 'un', size: 'P',  stock: 12, minStock: 5,  active: true,  image: 'https://picsum.photos/seed/tshirt3/300/400' },
  { id: 4,  barcode: '7891000400405', name: 'Camiseta Manga Longa Branca',       category: 'Camisetas',  costPrice: 32.00, salePrice: 69.90,  unit: 'un', size: 'M',  stock: 3,  minStock: 8,  active: true,  image: 'https://picsum.photos/seed/longsleeve/300/400' },
  { id: 5,  barcode: '7891000500509', name: 'Calca Jeans Skinny Escura',         category: 'Calcas',     costPrice: 55.00, salePrice: 129.90, unit: 'un', size: '40', stock: 22, minStock: 8,  active: true,  image: 'https://picsum.photos/seed/jeans1/300/400' },
  { id: 6,  barcode: '7891000600603', name: 'Calca Jeans Reta Classica',         category: 'Calcas',     costPrice: 50.00, salePrice: 119.90, unit: 'un', size: '42', stock: 15, minStock: 6,  active: true,  image: 'https://picsum.photos/seed/jeans2/300/400' },
  { id: 7,  barcode: '7891000700707', name: 'Calca Moletom Jogger Cinza',        category: 'Calcas',     costPrice: 40.00, salePrice: 89.90,  unit: 'un', size: 'G',  stock: 28, minStock: 10, active: true,  image: 'https://picsum.photos/seed/jogger/300/400' },
  { id: 8,  barcode: '7891000800801', name: 'Calca Social Slim Preta',           category: 'Calcas',     costPrice: 60.00, salePrice: 149.90, unit: 'un', size: '44', stock: 2,  minStock: 5,  active: true,  image: 'https://picsum.photos/seed/dress1/300/400' },
  { id: 9,  barcode: '7891000900905', name: 'Vestido Midi Floral Verao',         category: 'Vestidos',   costPrice: 65.00, salePrice: 159.90, unit: 'un', size: 'M',  stock: 10, minStock: 4,  active: true,  image: 'https://picsum.photos/seed/vestido1/300/400' },
  { id: 10, barcode: '7891001000109', name: 'Vestido Longo Festa Preto',         category: 'Vestidos',   costPrice: 90.00, salePrice: 219.90, unit: 'un', size: 'P',  stock: 6,  minStock: 3,  active: true,  image: 'https://picsum.photos/seed/vestido2/300/400' },
  { id: 11, barcode: '7891001100203', name: 'Vestido Curto Casual Jeans',        category: 'Vestidos',   costPrice: 55.00, salePrice: 139.90, unit: 'un', size: 'G',  stock: 8,  minStock: 4,  active: true,  image: 'https://picsum.photos/seed/vestido3/300/400' },
  { id: 12, barcode: '7891001200307', name: 'Bolsa Tote Couro Sintetico',        category: 'Acessorios', costPrice: 45.00, salePrice: 99.90,  unit: 'un', size: '-',  stock: 20, minStock: 5,  active: true,  image: 'https://picsum.photos/seed/bolsa1/300/400' },
  { id: 13, barcode: '7891001300401', name: 'Cinto Couro Masculino Marrom',      category: 'Acessorios', costPrice: 25.00, salePrice: 59.90,  unit: 'un', size: '-',  stock: 30, minStock: 10, active: true,  image: 'https://picsum.photos/seed/cinto/300/400' },
  { id: 14, barcode: '7891001400505', name: 'Oculos de Sol Aviador',             category: 'Acessorios', costPrice: 35.00, salePrice: 79.90,  unit: 'un', size: '-',  stock: 1,  minStock: 5,  active: true,  image: 'https://picsum.photos/seed/oculos/300/400' },
  { id: 15, barcode: '7891001500609', name: 'Relogio Analogico Classico',        category: 'Acessorios', costPrice: 80.00, salePrice: 189.90, unit: 'un', size: '-',  stock: 7,  minStock: 3,  active: true,  image: 'https://picsum.photos/seed/relogio/300/400' },
  { id: 16, barcode: '7891001600703', name: 'Tenis Casual Branco',               category: 'Calcados',   costPrice: 70.00, salePrice: 169.90, unit: 'par', size: '41', stock: 14, minStock: 5, active: true,  image: 'https://picsum.photos/seed/tenis1/300/400' },
  { id: 17, barcode: '7891001700807', name: 'Sandalia Rasteira Dourada',         category: 'Calcados',   costPrice: 30.00, salePrice: 69.90,  unit: 'par', size: '37', stock: 4,  minStock: 5, active: true,  image: 'https://picsum.photos/seed/sandalia/300/400' },
  { id: 18, barcode: '7891001800901', name: 'Bota Chelsea Preta Couro',          category: 'Calcados',   costPrice: 95.00, salePrice: 229.90, unit: 'par', size: '43', stock: 9,  minStock: 3, active: true,  image: 'https://picsum.photos/seed/bota1/300/400' },
];

// ---- STATE ----
let cart = [];
let saleDiscount = 0;
let saleNumber = 42;
let selectedPaymentMethod = 'cash';
let discountType = 'value';
let editingProductId = null;

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

// ============================================================
// SIDEBAR (overlay - hamburger menu)
// ============================================================
function openSidebar() {
  $('#sidebar').classList.add('open');
  $('#sidebar-overlay').classList.add('active');
}

function closeSidebar() {
  $('#sidebar').classList.remove('open');
  $('#sidebar-overlay').classList.remove('active');
}

$('#pdv-menu-btn').addEventListener('click', openSidebar);
$('#produtos-menu-btn').addEventListener('click', openSidebar);
$('#sidebar-close').addEventListener('click', closeSidebar);
$('#sidebar-overlay').addEventListener('click', closeSidebar);

// ============================================================
// NAVIGATION
// ============================================================
$$('.menu-item').forEach(item => {
  item.addEventListener('click', () => {
    $$('.menu-item').forEach(i => i.classList.remove('active'));
    item.classList.add('active');
    const page = item.dataset.page;
    $$('.page').forEach(p => p.classList.remove('active'));
    $(`#page-${page}`).classList.add('active');
    closeSidebar();
    if (page === 'produtos') renderProducts();
    if (page === 'pdv') setTimeout(() => $('#barcode-input').focus(), 100);
  });
});

// ============================================================
// CLOCK
// ============================================================
function updateClock() {
  const now = new Date();
  const timeEl = $('#pdv-time');
  if (timeEl) timeEl.textContent = now.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });
}
updateClock();
setInterval(updateClock, 1000);

function formatBRL(value) {
  return 'R$ ' + value.toFixed(2).replace('.', ',');
}

// ============================================================
// PDV - CART LOGIC
// ============================================================
function findProductByBarcode(code) {
  return PRODUCTS.find(p => p.barcode === code && p.active);
}

function findProductsBySearch(query) {
  const q = query.toLowerCase();
  return PRODUCTS.filter(p =>
    p.active && (
      p.name.toLowerCase().includes(q) ||
      p.barcode.includes(q) ||
      p.category.toLowerCase().includes(q)
    )
  ).slice(0, 8);
}

function addToCart(product) {
  const existing = cart.find(item => item.productId === product.id);
  if (existing) {
    existing.quantity++;
    existing.total = existing.quantity * existing.unitPrice;
  } else {
    cart.push({
      productId: product.id,
      productName: product.name,
      barcode: product.barcode,
      unitPrice: product.salePrice,
      quantity: 1,
      total: product.salePrice,
      size: product.size,
      unit: product.unit,
    });
  }
  updateHeaderProduct(product);
  renderCart();
}

function updateHeaderProduct(product) {
  const lastItem = cart.find(i => i.productId === product.id);
  const qty = lastItem ? lastItem.quantity : 1;
  const total = lastItem ? lastItem.total : product.salePrice;

  $('#pdv-product-name').textContent = product.name.toUpperCase();
  $('#pdv-product-calc').textContent = `${formatBRL(product.salePrice)} X ${qty} ${product.unit.toUpperCase()} = ${formatBRL(total)}`;
}

function renderCart() {
  const tbody = $('#cart-body');
  const emptyEl = $('#cart-empty');

  if (cart.length === 0) {
    emptyEl.classList.remove('hidden');
    $('#pdv-product-name').textContent = 'MENULY PDV';
    $('#pdv-product-calc').textContent = 'Aguardando leitura do codigo de barras...';
  } else {
    emptyEl.classList.add('hidden');
  }

  tbody.innerHTML = '';
  cart.forEach((item, idx) => {
    const tr = document.createElement('tr');
    const isLast = idx === cart.length - 1;
    if (isLast) tr.classList.add('highlight');

    tr.innerHTML = `
      <td>${item.productName}${item.size !== '-' ? ' (' + item.size + ')' : ''}</td>
      <td>${item.quantity}</td>
      <td>${formatBRL(item.unitPrice)}</td>
      <td>${formatBRL(item.total)}</td>
    `;

    // Double click to remove
    tr.addEventListener('dblclick', () => {
      cart.splice(idx, 1);
      renderCart();
    });

    tbody.appendChild(tr);
  });

  // Auto-scroll to last item
  const tableBody = tbody;
  if (tableBody.lastChild) {
    tableBody.lastChild.scrollIntoView({ behavior: 'smooth', block: 'end' });
  }

  updateTotals();
}

function updateTotals() {
  const subtotal = cart.reduce((sum, item) => sum + item.total, 0);
  const total = Math.max(0, subtotal - saleDiscount);
  $('#pdv-total').textContent = formatBRL(total);
  $('#cart-count').textContent = cart.length;

  if (saleDiscount > 0) {
    $('#pdv-discount-info').style.display = 'flex';
    $('#pdv-discount').textContent = '-' + formatBRL(saleDiscount);
  } else {
    $('#pdv-discount-info').style.display = 'none';
  }
}

// ---- BARCODE INPUT ----
$('#barcode-input').addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    e.preventDefault();
    const value = e.target.value.trim();
    if (!value) return;
    const product = findProductByBarcode(value);
    if (product) {
      addToCart(product);
      e.target.value = '';
      $('#search-results').classList.add('hidden');
    } else {
      showSearchResults(value);
    }
  }
});

$('#barcode-input').addEventListener('input', (e) => {
  const value = e.target.value.trim();
  if (value.length >= 2) showSearchResults(value);
  else $('#search-results').classList.add('hidden');
});

function showSearchResults(query) {
  const results = findProductsBySearch(query);
  const container = $('#search-results');
  if (results.length === 0) { container.classList.add('hidden'); return; }

  container.classList.remove('hidden');
  container.innerHTML = '';
  results.forEach(product => {
    const div = document.createElement('div');
    div.className = 'search-result-item';
    div.innerHTML = `
      <div class="search-result-info">
        <div class="sr-name">${product.name}</div>
        <div class="sr-detail">${product.category} | Tam: ${product.size} | Est: ${product.stock}</div>
      </div>
      <div style="text-align:right;flex-shrink:0">
        <div class="sr-price">${formatBRL(product.salePrice)}</div>
      </div>
    `;
    div.addEventListener('click', () => {
      addToCart(product);
      $('#barcode-input').value = '';
      container.classList.add('hidden');
      $('#barcode-input').focus();
    });
    container.appendChild(div);
  });
}

document.addEventListener('click', (e) => {
  if (!e.target.closest('.pdv-barcode-area')) $('#search-results').classList.add('hidden');
});

// ---- SHORTCUTS ----
$('#btn-f1').addEventListener('click', () => openPaymentModal());
$('#btn-f3').addEventListener('click', () => openDiscountModal());
$('#btn-f6').addEventListener('click', () => openReturnModal());
$('#btn-f4').addEventListener('click', () => cancelSale());

document.addEventListener('keydown', (e) => {
  if (!$('#page-pdv').classList.contains('active')) return;
  if (document.querySelector('.modal-overlay.active')) return;
  if (e.key === 'F1') { e.preventDefault(); openPaymentModal(); }
  if (e.key === 'F2') { e.preventDefault(); if (cart.length > 0) { cart.pop(); renderCart(); } }
  if (e.key === 'F3') { e.preventDefault(); openDiscountModal(); }
  if (e.key === 'F4') { e.preventDefault(); cancelSale(); }
  if (e.key === 'F6') { e.preventDefault(); openReturnModal(); }
});

function cancelSale() {
  if (cart.length === 0) return;
  if (confirm('Deseja cancelar toda a venda?')) { cart = []; saleDiscount = 0; renderCart(); }
}

// ============================================================
// PAYMENT MODAL
// ============================================================
function openPaymentModal() {
  if (cart.length === 0) return;
  const total = getTotal();
  $('#payment-total-value').textContent = formatBRL(total);
  $('#amount-received').value = '';
  $('#change-value').textContent = 'R$ 0,00';
  $('#change-value').classList.remove('negative');
  selectedPaymentMethod = 'cash';
  updatePaymentMethodUI();
  $('#modal-payment').classList.add('active');
  if (selectedPaymentMethod === 'cash') $('#amount-received').focus();
}

function getTotal() {
  const subtotal = cart.reduce((sum, item) => sum + item.total, 0);
  return Math.max(0, subtotal - saleDiscount);
}

$('#close-payment').addEventListener('click', () => $('#modal-payment').classList.remove('active'));

$$('.payment-btn').forEach(btn => {
  btn.addEventListener('click', () => { selectedPaymentMethod = btn.dataset.method; updatePaymentMethodUI(); });
});

function updatePaymentMethodUI() {
  $$('.payment-btn').forEach(b => b.classList.remove('active'));
  $(`.payment-btn[data-method="${selectedPaymentMethod}"]`).classList.add('active');
  if (selectedPaymentMethod === 'cash') $('#payment-cash-section').classList.remove('hidden');
  else $('#payment-cash-section').classList.add('hidden');
}

$('#amount-received').addEventListener('input', () => {
  const received = parseFloat($('#amount-received').value) || 0;
  const total = getTotal();
  const change = received - total;
  if (received === 0) { $('#change-value').textContent = 'R$ 0,00'; $('#change-value').classList.remove('negative'); }
  else if (change >= 0) { $('#change-value').textContent = formatBRL(change); $('#change-value').classList.remove('negative'); }
  else { $('#change-value').textContent = '-' + formatBRL(Math.abs(change)); $('#change-value').classList.add('negative'); }
});

$$('.quick-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const val = parseFloat(btn.dataset.value);
    const current = parseFloat($('#amount-received').value) || 0;
    $('#amount-received').value = (current + val).toFixed(2);
    $('#amount-received').dispatchEvent(new Event('input'));
  });
});

$('#btn-confirm-payment').addEventListener('click', () => {
  const total = getTotal();
  if (selectedPaymentMethod === 'cash') {
    const received = parseFloat($('#amount-received').value) || 0;
    if (received < total) { alert('Valor recebido insuficiente!'); return; }
  }
  const methodLabels = { cash: 'Dinheiro', card: 'Cartao', pix: 'Pix' };
  const received = parseFloat($('#amount-received').value) || total;
  const change = received - total;
  let details = `Venda #${String(saleNumber).padStart(6, '0')}<br>`;
  details += `Total: ${formatBRL(total)}<br>`;
  details += `Pagamento: ${methodLabels[selectedPaymentMethod]}`;
  if (selectedPaymentMethod === 'cash' && change > 0) details += `<br>Troco: ${formatBRL(change)}`;

  $('#modal-payment').classList.remove('active');
  $('#success-details').innerHTML = details;
  $('#modal-success').classList.add('active');
});

$('#btn-new-sale').addEventListener('click', () => {
  cart = []; saleDiscount = 0; saleNumber++;
  renderCart();
  $('#modal-success').classList.remove('active');
  $('#barcode-input').focus();
});

// ============================================================
// DISCOUNT MODAL
// ============================================================
function openDiscountModal() {
  if (cart.length === 0) return;
  discountType = 'value';
  updateDiscountTypeUI();
  $('#discount-input').value = '';
  $('#modal-discount').classList.add('active');
  $('#discount-input').focus();
}

$('#close-discount').addEventListener('click', () => $('#modal-discount').classList.remove('active'));

$$('.toggle-btn').forEach(btn => {
  btn.addEventListener('click', () => { discountType = btn.dataset.type; updateDiscountTypeUI(); });
});

function updateDiscountTypeUI() {
  $$('.toggle-btn').forEach(b => b.classList.remove('active'));
  $(`.toggle-btn[data-type="${discountType}"]`).classList.add('active');
  if (discountType === 'value') { $('#discount-label').textContent = 'Valor do desconto (R$):'; $('#discount-input').placeholder = '0,00'; }
  else { $('#discount-label').textContent = 'Percentual de desconto (%):'; $('#discount-input').placeholder = '0'; }
}

$('#btn-apply-discount').addEventListener('click', () => {
  const value = parseFloat($('#discount-input').value) || 0;
  const subtotal = cart.reduce((sum, item) => sum + item.total, 0);
  if (discountType === 'value') saleDiscount = Math.min(value, subtotal);
  else saleDiscount = subtotal * (Math.min(value, 100) / 100);
  updateTotals();
  $('#modal-discount').classList.remove('active');
});

// ============================================================
// PRODUCTS PAGE
// ============================================================
function renderProducts() {
  const searchQuery = ($('#product-search')?.value || '').toLowerCase();
  const categoryFilter = $('#category-filter')?.value || 'all';

  let filtered = PRODUCTS.filter(p => {
    const matchSearch = !searchQuery || p.name.toLowerCase().includes(searchQuery) || p.barcode.includes(searchQuery);
    const matchCategory = categoryFilter === 'all' || p.category === categoryFilter;
    return matchSearch && matchCategory;
  });

  $('#stat-total').textContent = PRODUCTS.length;
  $('#stat-active').textContent = PRODUCTS.filter(p => p.active).length;
  $('#stat-low-stock').textContent = PRODUCTS.filter(p => p.active && p.stock <= p.minStock).length;

  const grid = $('#produtos-grid');
  grid.innerHTML = '';

  filtered.forEach(product => {
    const isLowStock = product.stock <= product.minStock;
    const card = document.createElement('div');
    card.className = `product-card${!product.active ? ' inactive-overlay' : ''}`;

    const sizesHtml = product.size !== '-'
      ? `<div class="product-card-sizes"><span>${product.size}</span></div>`
      : '';

    card.innerHTML = `
      <div class="product-card-img">
        <img src="${product.image}" alt="${product.name}" onerror="this.outerHTML='<span class=\\'no-image\\'>&#128085;</span>'">
        <span class="stock-badge ${isLowStock ? 'low' : 'ok'}">${isLowStock ? 'Estoque Baixo' : 'Em Estoque'}</span>
      </div>
      <div class="product-card-body">
        <div class="product-card-category">${product.category}</div>
        <div class="product-card-name" title="${product.name}">${product.name}</div>
        <div class="product-card-barcode">${product.barcode}</div>
        <div class="product-card-prices">
          <span class="product-card-sale-price">${formatBRL(product.salePrice)}</span>
          <span class="product-card-cost-price">Custo: ${formatBRL(product.costPrice)}</span>
        </div>
        ${sizesHtml}
        <div class="product-card-stock ${isLowStock ? 'low' : ''}">
          ${isLowStock ? '&#9888; ' : ''}Estoque: ${product.stock} ${product.unit} (min: ${product.minStock})
        </div>
        <div class="product-card-actions">
          <button class="btn btn-outline btn-sm btn-edit" data-id="${product.id}">Editar</button>
          <button class="btn btn-danger btn-sm btn-toggle-active" data-id="${product.id}">
            ${product.active ? 'Inativar' : 'Ativar'}
          </button>
        </div>
      </div>
    `;
    grid.appendChild(card);
  });

  grid.querySelectorAll('.btn-edit').forEach(btn => {
    btn.addEventListener('click', () => {
      const product = PRODUCTS.find(p => p.id === parseInt(btn.dataset.id));
      if (product) openProductModal(product);
    });
  });

  grid.querySelectorAll('.btn-toggle-active').forEach(btn => {
    btn.addEventListener('click', () => {
      const product = PRODUCTS.find(p => p.id === parseInt(btn.dataset.id));
      if (product) { product.active = !product.active; renderProducts(); }
    });
  });
}

$('#product-search')?.addEventListener('input', () => renderProducts());
$('#category-filter')?.addEventListener('change', () => renderProducts());

// ---- Product Modal ----
$('#btn-new-product').addEventListener('click', () => openProductModal(null));

function openProductModal(product) {
  editingProductId = product ? product.id : null;
  $('#modal-product-title').textContent = product ? 'Editar Produto' : 'Novo Produto';
  $('#prod-barcode').value = product ? product.barcode : '';
  $('#prod-name').value = product ? product.name : '';
  $('#prod-category').value = product ? product.category : 'Camisetas';
  $('#prod-unit').value = product ? product.unit : 'un';
  $('#prod-cost').value = product ? product.costPrice : '';
  $('#prod-price').value = product ? product.salePrice : '';
  $('#prod-stock').value = product ? product.stock : '';
  $('#prod-min-stock').value = product ? product.minStock : '';

  const preview = $('#image-preview');
  if (product && product.image) {
    preview.innerHTML = `<img src="${product.image}" alt="Preview" onerror="this.outerHTML='<span class=\\'upload-icon\\'>&#128247;</span><p>Clique para adicionar imagem</p>'">`;
  } else {
    preview.innerHTML = '<span class="upload-icon">&#128247;</span><p>Clique para adicionar imagem</p>';
  }
  $('#modal-product').classList.add('active');
}

$('#close-product').addEventListener('click', () => $('#modal-product').classList.remove('active'));
$('#btn-cancel-product').addEventListener('click', () => $('#modal-product').classList.remove('active'));

$('#image-upload-area').addEventListener('click', () => $('#prod-image').click());
$('#prod-image').addEventListener('change', (e) => {
  const file = e.target.files[0];
  if (file) {
    const reader = new FileReader();
    reader.onload = (ev) => { $('#image-preview').innerHTML = `<img src="${ev.target.result}" alt="Preview">`; };
    reader.readAsDataURL(file);
  }
});

$('#btn-save-product').addEventListener('click', () => {
  const barcode = $('#prod-barcode').value.trim();
  const name = $('#prod-name').value.trim();
  const costPrice = parseFloat($('#prod-cost').value) || 0;
  const salePrice = parseFloat($('#prod-price').value) || 0;

  if (!barcode || !name || !salePrice) { alert('Preencha os campos obrigatorios: Codigo de barras, Nome e Preco de Venda.'); return; }

  if (editingProductId) {
    const product = PRODUCTS.find(p => p.id === editingProductId);
    if (product) {
      product.barcode = barcode; product.name = name;
      product.category = $('#prod-category').value; product.unit = $('#prod-unit').value;
      product.costPrice = costPrice; product.salePrice = salePrice;
      product.stock = parseInt($('#prod-stock').value) || 0;
      product.minStock = parseInt($('#prod-min-stock').value) || 0;
      const previewImg = $('#image-preview img');
      if (previewImg && previewImg.src.startsWith('data:')) product.image = previewImg.src;
    }
  } else {
    const newId = Math.max(...PRODUCTS.map(p => p.id)) + 1;
    const previewImg = $('#image-preview img');
    PRODUCTS.push({
      id: newId, barcode, name, category: $('#prod-category').value,
      costPrice, salePrice, unit: $('#prod-unit').value, size: 'M',
      stock: parseInt($('#prod-stock').value) || 0,
      minStock: parseInt($('#prod-min-stock').value) || 0,
      active: true, image: previewImg ? previewImg.src : `https://picsum.photos/seed/prod${newId}/300/400`,
    });
  }
  $('#modal-product').classList.remove('active');
  renderProducts();
});

// ============================================================
// RETURNS / DEVOLUÇÕES (F6)
// ============================================================

// Simulated completed sales history
const COMPLETED_SALES = [
  {
    id: 1001, date: '2026-02-22 10:35', clientName: 'Ana Souza',
    items: [
      { productId: 1, productName: 'Camiseta Basica Algodao Preta', qty: 2, unitPrice: 49.90, size: 'M' },
      { productId: 5, productName: 'Calca Jeans Skinny Escura', qty: 1, unitPrice: 129.90, size: '40' },
    ]
  },
  {
    id: 1002, date: '2026-02-23 14:20', clientName: 'Carlos Lima',
    items: [
      { productId: 9, productName: 'Vestido Midi Floral Verao', qty: 1, unitPrice: 159.90, size: 'M' },
      { productId: 12, productName: 'Bolsa Tote Couro Sintetico', qty: 1, unitPrice: 99.90, size: '-' },
    ]
  },
  {
    id: 1003, date: '2026-02-24 09:15', clientName: 'Juliana Ferreira',
    items: [
      { productId: 16, productName: 'Tenis Casual Branco', qty: 1, unitPrice: 169.90, size: '41' },
      { productId: 13, productName: 'Cinto Couro Masculino Marrom', qty: 1, unitPrice: 59.90, size: '-' },
      { productId: 3, productName: 'Camiseta Estampada Floral', qty: 3, unitPrice: 59.90, size: 'P' },
    ]
  },
];

let returnStep = 1;
let currentReturnSale = null;

function openReturnModal() {
  returnStep = 1;
  currentReturnSale = null;
  $('#return-sale-input').value = '';
  $('#return-sale-info').classList.add('hidden');
  $('#return-step-2').classList.add('hidden');
  $('#return-step-1').classList.remove('hidden');
  $('#btn-next-return').classList.remove('hidden');
  $('#btn-confirm-return').classList.add('hidden');
  $('#modal-return').classList.add('active');
  setTimeout(() => $('#return-sale-input').focus(), 100);
}

$('#close-return').addEventListener('click', () => $('#modal-return').classList.remove('active'));
$('#btn-cancel-return').addEventListener('click', () => $('#modal-return').classList.remove('active'));

// Search sale
$('#btn-search-sale').addEventListener('click', searchSale);
$('#return-sale-input').addEventListener('keydown', (e) => { if (e.key === 'Enter') searchSale(); });

function searchSale() {
  const saleId = parseInt($('#return-sale-input').value);
  const sale = COMPLETED_SALES.find(s => s.id === saleId);
  if (!sale) {
    alert('Venda nao encontrada! Tente: 1001, 1002 ou 1003');
    return;
  }
  currentReturnSale = sale;
  $('#return-sale-id').textContent = sale.id;
  $('#return-sale-date').textContent = sale.date;
  $('#return-sale-client').textContent = sale.clientName;

  const tbody = $('#return-items-body');
  tbody.innerHTML = sale.items.map((item, i) => `
    <tr data-index="${i}">
      <td><input type="checkbox" class="return-check" data-index="${i}"></td>
      <td>${item.productName}${item.size !== '-' ? ' (' + item.size + ')' : ''}</td>
      <td>${item.qty}</td>
      <td><input type="number" class="return-qty" data-index="${i}" value="${item.qty}" min="1" max="${item.qty}" disabled></td>
      <td>${formatBRL(item.unitPrice)}</td>
      <td class="return-subtotal" data-index="${i}">${formatBRL(item.unitPrice * item.qty)}</td>
    </tr>
  `).join('');

  // Checkbox events
  tbody.querySelectorAll('.return-check').forEach(cb => {
    cb.addEventListener('change', (e) => {
      const idx = e.target.dataset.index;
      const qtyInput = tbody.querySelector(`.return-qty[data-index="${idx}"]`);
      const row = e.target.closest('tr');
      if (e.target.checked) {
        qtyInput.disabled = false;
        row.classList.add('selected-return');
      } else {
        qtyInput.disabled = true;
        row.classList.remove('selected-return');
      }
      updateReturnTotal();
    });
  });

  // Qty change events
  tbody.querySelectorAll('.return-qty').forEach(input => {
    input.addEventListener('input', () => updateReturnTotal());
  });

  // Select all
  $('#return-select-all').checked = false;
  $('#return-select-all').onchange = (e) => {
    tbody.querySelectorAll('.return-check').forEach(cb => {
      cb.checked = e.target.checked;
      cb.dispatchEvent(new Event('change'));
    });
  };

  updateReturnTotal();
  $('#return-sale-info').classList.remove('hidden');
}

function updateReturnTotal() {
  if (!currentReturnSale) return;
  let total = 0;
  const tbody = $('#return-items-body');
  currentReturnSale.items.forEach((item, i) => {
    const cb = tbody.querySelector(`.return-check[data-index="${i}"]`);
    const qtyInput = tbody.querySelector(`.return-qty[data-index="${i}"]`);
    const subtotalTd = tbody.querySelector(`.return-subtotal[data-index="${i}"]`);
    if (cb && cb.checked) {
      const qty = parseInt(qtyInput.value) || 0;
      const sub = qty * item.unitPrice;
      subtotalTd.textContent = formatBRL(sub);
      total += sub;
    } else {
      subtotalTd.textContent = formatBRL(0);
    }
  });
  $('#return-total-value').textContent = formatBRL(total);
}

// Next / Confirm buttons
$('#btn-next-return').addEventListener('click', () => {
  if (returnStep === 1) {
    if (!currentReturnSale) { alert('Busque uma venda primeiro!'); return; }
    const checked = $$('#return-items-body .return-check:checked');
    if (checked.length === 0) { alert('Selecione ao menos um item para devolver!'); return; }
    returnStep = 2;
    $('#return-step-2').classList.remove('hidden');
    $('#btn-next-return').classList.add('hidden');
    $('#btn-confirm-return').classList.remove('hidden');
  }
});

$('#btn-confirm-return').addEventListener('click', () => {
  const tipo = $('#return-type').value;
  const restituicao = $('#return-restituicao').value;
  const motivo = $('#return-motivo').value;
  const totalStr = $('#return-total-value').textContent;

  // Simulate returning items to stock
  const tbody = $('#return-items-body');
  currentReturnSale.items.forEach((item, i) => {
    const cb = tbody.querySelector(`.return-check[data-index="${i}"]`);
    const qtyInput = tbody.querySelector(`.return-qty[data-index="${i}"]`);
    if (cb && cb.checked) {
      const qty = parseInt(qtyInput.value) || 0;
      const product = PRODUCTS.find(p => p.id === item.productId);
      if (product) product.stock += qty;
    }
  });

  $('#modal-return').classList.remove('active');

  // Show success
  const tipoLabel = tipo === 'troca' ? 'Troca' : 'Devoluçao';
  const restLabel = restituicao === 'credito' ? 'Credito/Vale gerado' : restituicao === 'dinheiro' ? 'Estorno em dinheiro' : 'Troca direta';
  $('#return-success-title').textContent = `${tipoLabel} Processada!`;
  $('#return-success-details').innerHTML = `Venda #${currentReturnSale.id}<br>Valor: ${totalStr}<br>${restLabel}<br>Motivo: ${motivo}`;

  if (tipo === 'troca' || restituicao === 'troca') {
    $('#btn-start-exchange').classList.remove('hidden');
  } else {
    $('#btn-start-exchange').classList.add('hidden');
  }

  $('#modal-return-success').classList.add('active');
});

$('#btn-return-done').addEventListener('click', () => {
  $('#modal-return-success').classList.remove('active');
  renderProducts();
});

$('#btn-start-exchange').addEventListener('click', () => {
  // Start new sale with credit applied
  const totalText = $('#return-total-value').textContent;
  const creditValue = parseFloat(totalText.replace('R$', '').replace('.', '').replace(',', '.').trim()) || 0;
  $('#modal-return-success').classList.remove('active');
  cart = [];
  saleDiscount = 0;
  renderCart();
  if (creditValue > 0) {
    saleDiscount = creditValue;
    renderCart();
    alert(`Nova venda iniciada com credito de ${formatBRL(creditValue)} aplicado como desconto!`);
  }
  $('#barcode-input').focus();
});

// ---- Close modals ----
$$('.modal-overlay').forEach(overlay => {
  overlay.addEventListener('click', (e) => { if (e.target === overlay) overlay.classList.remove('active'); });
});
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    $$('.modal-overlay.active').forEach(m => m.classList.remove('active'));
    closeSidebar();
  }
});

// ---- INIT ----
renderCart();
$('#barcode-input').focus();
