import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ArrowLeft, ArrowRight, ArrowUpRight, Award, BadgeCheck, Bell, BellRing,
  Check, CheckCircle2, ChevronDown, ChevronLeft, ChevronRight, ClipboardList,
  Clock, Copy, CreditCard, Download, Droplets, FileText, FlaskConical, Gift,
  Heart, HelpCircle, Home, Leaf, MapPin, Minus, Navigation, Package,
  PackageCheck, Plus, RotateCcw, Search, Settings, ShieldCheck, ShoppingBag,
  SlidersHorizontal, Sparkles, Star, Thermometer, TicketPercent, Trash2,
  Truck, User, Wallet, Wheat, X, Zap,
} from 'lucide-react'
import {
  IMG, categories, products, bundles, ranked, labTests, nutrition,
  benchmarks, testimonials,
} from './data.js'
import './phone.css'
import './phone-theme.css'

const money = (n) => `₹${Number(n).toLocaleString('en-IN')}`

function Stars({ value, size = 11 }) {
  return <span className="pa-stars">{[1, 2, 3, 4, 5].map((i) => <Star key={i} size={size} fill={i <= Math.round(value) ? 'currentColor' : 'none'} strokeWidth={1.6} />)}</span>
}

function Pack({ src, className = '', alt = '', style }) {
  return <img className={`pa-pack ${className}`} src={src} alt={alt} style={style} />
}

const HEROES = [
  {
    id: 'h1', pill: 'NEW HARVEST COLLECTION • 100% COLD STONEGROUND',
    title: 'Discover The', accent: 'Purest', tail: 'Chakki Atta Online',
    desc: 'Shop 100% honest stoneground flours milled below 28°C. Triple-washed grains, full bran retention, zero maida, zero bleaching agents.',
    pack: IMG.khapli, tone: 'cream', price: 95, product: 0,
  },
  {
    id: 'h2', pill: '36g PROTEIN • WHEAT + SOYA + PEANUT',
    title: 'Flour that', accent: 'works', tail: 'harder for you.',
    desc: 'Cold-stoneground high-protein blend for softer rotis, better hydration and all-day energy.',
    pack: IMG.protein, tone: 'orange', price: 115, product: 1,
  },
  {
    id: 'h3', pill: 'FAMILY SACKS • 1KG – 10KG',
    title: 'One sack,', accent: 'all', tail: 'month of rotis.',
    desc: 'The same honest Khapli atta in carry-handle and family sizes, delivered fresh by EV van.',
    pack: IMG.family, tone: 'gold', price: 849, product: 2,
  },
]

const TABS = [
  { id: 'home', label: 'Home', icon: Home },
  { id: 'shop', label: 'Shop', icon: Search },
  { id: 'lab', label: 'Lab', icon: FlaskConical },
  { id: 'cart', label: 'Basket', icon: ShoppingBag },
  { id: 'profile', label: 'Profile', icon: User },
]

const VIEWER_PACKS = [IMG.khapli, IMG.protein, IMG.family, IMG.badges, IMG.duo, IMG.handle]
const NOTIFICATIONS = [
  { icon: PackageCheck, title: 'Order #IC40821 delivered', text: 'Your Khapli 10kg sack arrived in 94 minutes.', time: 'Today, 9:41 AM' },
  { icon: Wheat, title: 'New harvest is live', text: 'Batch #IC-0426 is milled below 28°C and lab-tested.', time: 'Yesterday' },
  { icon: TicketPercent, title: 'CLEAR50 is waiting', text: 'Get ₹50 off your next stoneground order.', time: '2 days ago' },
  { icon: Truck, title: 'EV delivery expanded', text: '2-hour delivery is now available at pincode 226001.', time: '4 days ago' },
]

export default function PhoneApp() {
  const [tab, setTab] = useState('home')
  const [screen, setScreen] = useState(null)
  const [backStack, setBackStack] = useState([])
  const [active, setActive] = useState(null)
  const [cart, setCart] = useState([])
  const [wish, setWish] = useState(['khapli', 'protein'])
  const [toast, setToast] = useState(null)
  const [sizeIdx, setSizeIdx] = useState(0)
  const [qty, setQty] = useState(1)
  const [detailTab, setDetailTab] = useState('overview')
  const [photo, setPhoto] = useState(0)
  const [coupon, setCoupon] = useState('')
  const [couponApplied, setCouponApplied] = useState(false)
  const [filter, setFilter] = useState('All')
  const [sort, setSort] = useState('featured')
  const [query, setQuery] = useState('')
  const [heroIdx, setHeroIdx] = useState(0)
  const [pin, setPin] = useState('226001')
  const [members, setMembers] = useState(4)
  const [rotis, setRotis] = useState(16)
  const [notif, setNotif] = useState(true)
  const [slot, setSlot] = useState('2-hour EV')
  const [payment, setPayment] = useState('UPI')
  const [address, setAddress] = useState({
    name: 'Aarav Sharma', phone: '+91 98765 43210',
    line: '12, Green Park', city: 'Lucknow, Uttar Pradesh', pin: '226001',
  })
  const [orderIds, setOrderIds] = useState(['IC40821', 'IC39744', 'IC38109'])
  const [viewerIdx, setViewerIdx] = useState(0)
  const [viewerAngle, setViewerAngle] = useState(0)
  const [clock, setClock] = useState({ d: '02', h: '14', m: '37', s: '11' })
  const orderId = useRef(`IC${Math.floor(10000 + Math.random() * 89999)}`)
  const toastTimer = useRef(null)
  const scrollRef = useRef(null)
  const viewerDrag = useRef(null)
  const deadline = useRef(Date.now() + ((2 * 24 + 14) * 3600 + 37 * 60 + 11) * 1000)

  useEffect(() => {
    const pad = (n) => String(Math.max(0, n)).padStart(2, '0')
    const tick = () => {
      const t = Math.max(0, Math.floor((deadline.current - Date.now()) / 1000))
      setClock({ d: pad(Math.floor(t / 86400)), h: pad(Math.floor(t / 3600) % 24), m: pad(Math.floor(t / 60) % 60), s: pad(t % 60) })
    }
    tick(); const id = setInterval(tick, 1000); return () => clearInterval(id)
  }, [])
  useEffect(() => {
    if (screen !== null || tab !== 'home') return
    const id = setInterval(() => setHeroIdx((i) => (i + 1) % HEROES.length), 5600)
    return () => clearInterval(id)
  }, [screen, tab])

  const showToast = (msg) => {
    clearTimeout(toastTimer.current)
    setToast({ msg, id: Date.now() })
    toastTimer.current = setTimeout(() => setToast(null), 2800)
  }
  const top = () => scrollRef.current?.scrollTo({ top: 0, behavior: 'smooth' })
  const goTab = (t) => { setTab(t); setScreen(null); setBackStack([]); top() }
  const goScreen = (s) => {
    setBackStack((stack) => [...stack, screen ? `screen:${screen}` : `tab:${tab}`])
    setScreen(s); top()
  }
  const goBack = () => {
    const last = backStack[backStack.length - 1]
    setBackStack((stack) => stack.slice(0, -1))
    if (!last) { setScreen(null); return }
    if (last.startsWith('tab:')) { setTab(last.slice(4)); setScreen(null) }
    else setScreen(last.slice(7))
  }

  const addItem = (item) => {
    const key = `${item.id}__${item.size}`
    setCart((c) => {
      const f = c.find((l) => l.key === key)
      return f ? c.map((l) => l.key === key ? { ...l, qty: l.qty + item.qty } : l) : [...c, { ...item, key, qty: item.qty }]
    })
    showToast(`${item.name} · ${item.size} added`)
  }
  const toggleWish = (id) => {
    setWish((w) => w.includes(id) ? w.filter((x) => x !== id) : [...w, id])
    showToast(wish.includes(id) ? 'Removed from saved' : 'Saved for later')
  }
  const openProduct = (p) => {
    setActive(p); setSizeIdx(0); setQty(1); setPhoto(0); setDetailTab('overview')
    goScreen('product')
  }
  const openSearch = () => goScreen('search')

  const cartCount = cart.reduce((a, l) => a + l.qty, 0)
  const subtotal = cart.reduce((a, l) => a + l.qty * l.price, 0)
  const savings = cart.reduce((a, l) => a + l.qty * ((l.mrp || l.price) - l.price), 0)
  const discount = couponApplied ? Math.min(50, subtotal) : 0
  const shipping = subtotal >= 499 || subtotal === 0 ? 0 : 49
  const total = subtotal - discount + shipping
  const shipLeft = Math.max(0, 499 - subtotal)

  const filtered = useMemo(() => {
    let l = filter === 'All' ? [...products] : products.filter((p) => p.groups.includes(filter))
    if (sort === 'low') l.sort((a, b) => a.sizes[0].price - b.sizes[0].price)
    if (sort === 'rating') l.sort((a, b) => b.rating - a.rating)
    return l
  }, [filter, sort])
  const results = useMemo(() => {
    const q = query.trim().toLowerCase()
    const all = [...products, ...bundles.map((b) => ({ ...b, subtitle: b.desc, image: b.image, id: b.id, price: b.price, mrp: b.mrp, sizes: [{ label: 'Monthly bundle', price: b.price, mrp: b.mrp }] }))]
    if (!q) return products.slice(0, 4)
    return all.filter((p) => `${p.name} ${p.subtitle || ''}`.toLowerCase().includes(q))
  }, [query])

  const monthly = rotis * 30
  const clearKg = monthly / 36
  const factoryKg = monthly / 28
  const savedKg = (factoryKg - clearKg).toFixed(1)
  const gallery = active ? [active.image, IMG.khapli, IMG.protein, IMG.family, IMG.badges].filter((x, i, a) => a.indexOf(x) === i).slice(0, 4) : []
  const size = active?.sizes[sizeIdx]

  const AppBar = ({ title, sub, right, back = false }) => (
    <div className="pa-appbar">
      {back ? <button className="pa-round" onClick={goBack} aria-label="Back"><ArrowLeft size={17} /></button>
        : <div className="pa-logo"><span className="pa-logo-mark"><Wheat size={15} /></span><span>itsclear<em>™</em></span></div>}
      <div className="pa-appbar-text"><strong>{title}</strong>{sub && <small>{sub}</small>}</div>
      {right || <button className="pa-round" onClick={openSearch} aria-label="Search"><Search size={17} /></button>}
    </div>
  )

  const ProductCard = ({ p, compact = false }) => (
    <div className={`pa-product ${compact ? 'pa-product--rail' : ''}`}>
      <div className={`pa-product-media tone-${p.tone || 'green'}`} onClick={() => openProduct(p)}>
        <Pack src={p.image} alt={p.name} />
        <span className="pa-tag">{p.tag}</span>
        <button className={`pa-wish ${wish.includes(p.id) ? 'on' : ''}`} onClick={(e) => { e.stopPropagation(); toggleWish(p.id) }} aria-label="Save"><Heart size={14} fill={wish.includes(p.id) ? 'currentColor' : 'none'} /></button>
      </div>
      <div className="pa-product-body">
        <strong onClick={() => openProduct(p)}>{p.name}</strong>
        <small>{p.subtitle}</small>
        <div className="pa-product-rating"><Stars value={p.rating} size={9} /><span>{p.rating.toFixed(1)} · {p.reviews} reviews</span></div>
        <div className="pa-product-foot">
          <div><b>{money(p.sizes[0].price)}</b><s>{money(p.sizes[0].mrp)}</s></div>
          <button className="pa-add" onClick={() => addItem({ id: p.id, name: p.name, image: p.image, size: p.sizes[0].label, price: p.sizes[0].price, mrp: p.sizes[0].mrp, qty: 1 })} aria-label="Add"><Plus size={15} /></button>
        </div>
      </div>
    </div>
  )

  /* ---------- HOME ---------- */
  const HomeScreen = () => (
    <>
      <AppBar title="Delivering to" sub="Lucknow, Uttar Pradesh" right={
        <div className="pa-appbar-actions">
          <button className="pa-round" onClick={() => goScreen('wishlist')} aria-label="Saved"><Heart size={16} /></button>
          <button className="pa-round pa-bell" onClick={() => goScreen('notifications')} aria-label="Notifications"><BellRing size={16} /><i /></button>
        </div>
      } />
      <div className="pa-location"><MapPin size={12} /> {pin} <button onClick={() => showToast('Delivery area: 2-hour EV available')}><ChevronDown size={13} /></button></div>

      <div className="pa-hero-wrap">
        <div className={`pa-hero tone-${HEROES[heroIdx].tone}`}>
          <div className="pa-hero-copy">
            <span className="pa-hero-pill">{HEROES[heroIdx].pill}</span>
            <h1 className="display">{HEROES[heroIdx].title} <em>{HEROES[heroIdx].accent}</em><br />{HEROES[heroIdx].tail}</h1>
            <p>{HEROES[heroIdx].desc}</p>
            <div className="pa-hero-actions">
              <button className="pa-hero-btn" onClick={() => openProduct(products[HEROES[heroIdx].product])}>Shop the harvest <ArrowRight size={14} /></button>
              <button className="pa-hero-secondary" onClick={() => goTab('lab')}>The zero-maida lab</button>
            </div>
          </div>
          <Pack key={HEROES[heroIdx].id} src={HEROES[heroIdx].pack} className="pa-hero-pack" />
          <button className="pa-hero-viewer" onClick={() => goScreen('viewer')}><RotateCcw size={13} /> Drag 360° to inspect authentic packaging <span>Reset</span></button>
        </div>
        <div className="pa-dots">{HEROES.map((h, i) => <button key={h.id} className={i === heroIdx ? 'on' : ''} onClick={() => setHeroIdx(i)} aria-label={`Slide ${i + 1}`} />)}</div>
      </div>

      <div className="pa-trust-row">
        {[[Truck, 'Free shipping'], [Thermometer, 'Cold milled'], [ShieldCheck, 'Zero maida'], [Zap, '2-hour EV']].map(([I, t]) => (
          <div className="pa-trust" key={t}><span><I size={15} /></span>{t}</div>
        ))}
      </div>

      <div className="pa-quick-grid">
        {[
          [Navigation, 'Track order', 'Live EV status', () => goScreen('tracking')],
          [BadgeCheck, 'Verify pack', 'Batch #IC-0426', () => goTab('lab')],
          [TicketPercent, 'Offers', 'CLEAR50 is live', () => goScreen('offers')],
          [Droplets, 'Calculator', 'Rotis per kg', () => goScreen('calc')],
        ].map(([I, t, s, fn]) => (
          <button className="pa-quick" key={t} onClick={fn}><span><I size={18} /></span><strong>{t}</strong><small>{s}</small></button>
        ))}
      </div>

      <div className="pa-section-head"><div><span className="pa-eyebrow">FIND YOUR FLOUR</span><h2 className="display">Shop by category</h2></div><button onClick={() => goTab('shop')}>See all <ChevronRight size={14} /></button></div>
      <div className="pa-cat-row">
        {categories.map((c) => (
          <button className="pa-cat" key={c.name} onClick={() => { setFilter(c.filter === 'All' ? 'All' : c.filter); goTab('shop') }}>
            <div className={`pa-cat-img tone-${c.filter === 'Protein' ? 'clay' : c.filter === 'Family' ? 'sand' : 'green'}`}><Pack src={c.image} /></div>
            <strong>{c.name}</strong><small>{c.note}</small>
          </button>
        ))}
      </div>

      <div className="pa-section-head"><div><span className="pa-eyebrow">THE FAVOURITES</span><h2 className="display">Best sellers</h2></div><button onClick={() => goTab('shop')}>See all <ChevronRight size={14} /></button></div>
      <div className="pa-rail">{products.slice(0, 4).map((p) => <ProductCard key={p.id} p={p} compact />)}</div>

      <div className="pa-section-head"><div><span className="pa-eyebrow">SLOW MILLED, HONESTLY</span><h2 className="display">Made the clear way</h2></div><button onClick={() => goTab('lab')}>Our standard <ChevronRight size={14} /></button></div>
      <div className="pa-story-grid">
        <button className="pa-story-card" onClick={() => goTab('lab')}>
          <img src={IMG.chakki} alt="Traditional stone chakki" />
          <span className="pa-story-overlay"><small>01 · COLD MILLED</small><strong>Below 28°C</strong><em>Live enzymes intact</em></span>
        </button>
        <button className="pa-story-card" onClick={() => goScreen('calc')}>
          <img src={IMG.roti} alt="Fresh soft rotis" />
          <span className="pa-story-overlay"><small>02 · BETTER YIELD</small><strong>36 rotis / kg</strong><em>Soft for 14 hours</em></span>
        </button>
      </div>

      <div className="pa-promise-card">
        <div className="pa-promise-copy"><span className="pa-eyebrow pa-eyebrow--light">THE CLEAR STANDARD</span><strong>Nothing added.<br />Nothing removed.</strong><p>6 lab tests · 0 maida · 0 bleach · 100% bran retained</p><button onClick={() => goTab('lab')}>See lab report <ArrowUpRight size={13} /></button></div>
        <Pack src={IMG.badges} className="pa-promise-pack" alt="Lab-certified pack" />
      </div>

      <button className="pa-sale" onClick={() => goScreen('offers')}>
        <div><span className="pa-kicker pa-kicker--gold"><Sparkles size={11} /> LIMITED TIME</span><strong>Super Sale · up to 25% off</strong><small>Use code <b>CLEAR50</b> on selected attas</small></div>
        <div className="pa-sale-clock"><b>{clock.d}</b><span>d</span><b>{clock.h}</b><span>h</span><b>{clock.m}</b><span>m</span></div>
      </button>

      <button className="pa-lab-promo" onClick={() => goTab('lab')}>
        <span className="pa-lab-promo-icon"><FlaskConical size={20} /></span>
        <div><span className="pa-eyebrow pa-eyebrow--light">ZERO-MAIDA LAB</span><strong>Proof, not promises.</strong><small>NABL batch certificate · 6/6 tests passed</small></div>
        <ArrowUpRight size={17} />
      </button>

      <button className="pa-calc-promo" onClick={() => goScreen('calc')}>
        <span><Droplets size={19} /></span><div><strong>How much atta does your family need?</strong><small>36 rotis per kg · find your perfect pack</small></div><ChevronRight size={17} />
      </button>

      <div className="pa-section-head"><div><span className="pa-eyebrow">POPULAR THIS MONTH</span><h2 className="display">Top ranked</h2></div></div>
      <div className="pa-rank-list">
        {ranked.slice(0, 3).map((r, i) => (
          <div className="pa-rank" key={r.name}><span>#{String(i + 1).padStart(2, '0')}</span><Pack src={r.image} /><div><strong>{r.name}</strong><small><Stars value={r.rating} size={9} /> {r.rating.toFixed(1)} · {r.size}</small></div><b>{money(r.price)}</b></div>
        ))}
      </div>
      <div className="pa-foot-note"><Wheat size={14} /> 100% whole grain · nothing else</div>
    </>
  )

  /* ---------- SHOP ---------- */
  const ShopScreen = () => (
    <>
      <AppBar title="All attas" sub={`${products.length} flours · 3 bundles`} right={<button className="pa-round" onClick={openSearch} aria-label="Search"><Search size={17} /></button>} />
      <button className="pa-searchbar" onClick={openSearch}><Search size={16} /> Search khapli, protein, family packs… <SlidersHorizontal size={15} /></button>
      <div className="pa-chips">
        {['All', 'Khapli', 'Protein', 'Family', 'Bundle'].map((f) => <button key={f} className={filter === f ? 'on' : ''} onClick={() => setFilter(f)}>{f === 'All' ? 'All attas' : f}</button>)}
      </div>
      <div className="pa-shop-meta"><span>{filtered.length} products</span><div className="pa-sort">{[['featured', 'Featured'], ['low', 'Price'], ['rating', 'Rated']].map(([k, l]) => <button key={k} className={sort === k ? 'on' : ''} onClick={() => setSort(k)}>{l}</button>)}</div></div>
      <div className="pa-grid">{filtered.map((p) => <ProductCard key={p.id} p={p} />)}</div>
      {filtered.length === 0 && <div className="pa-empty">No flours here. <button onClick={() => setFilter('All')}>Show all</button></div>}
      <div className="pa-section-head"><div><span className="pa-eyebrow">BETTER TOGETHER</span><h2 className="display">Monthly bundles</h2></div></div>
      <div className="pa-rail">
        {bundles.map((b) => (
          <div className="pa-bundle" key={b.id}>
            <div className="pa-bundle-media tone-sand"><Pack src={b.image} /><span className="pa-tag">{b.label}</span></div>
            <div className="pa-bundle-body"><strong>{b.name}</strong><small>{b.desc}</small><div><b>{money(b.price)}</b><s>{money(b.mrp)}</s></div>
              <button className="pa-bundle-add" onClick={() => addItem({ id: b.id, name: b.name, image: b.image, size: 'Monthly bundle', price: b.price, mrp: b.mrp, qty: 1 })}>Add to basket <Plus size={13} /></button></div>
          </div>
        ))}
      </div>
      <div className="pa-foot-note"><Truck size={14} /> Free shipping on orders over ₹499</div>
    </>
  )

  /* ---------- LAB ---------- */
  const LabScreen = () => (
    <>
      <AppBar title="Zero-Maida Lab" sub="Batch #IC-0426" right={<button className="pa-round" onClick={() => showToast('Batch certificate saved')} aria-label="Download"><Download size={16} /></button>} />
      <div className="pa-lab-hero"><FlaskConical size={22} /><div><strong>Proof, not promises.</strong><p>Every harvest batch is tested at an NABL-accredited lab. The certificate travels with your pack.</p></div></div>
      <div className="pa-cert">
        <div className="pa-cert-seal"><BadgeCheck size={18} /><span>NABL<br />VERIFIED</span></div>
        <div className="pa-cert-head"><div><strong>Batch Purity Certificate</strong><small>NABL · Report IC-0426/26</small></div><span><CheckCircle2 size={12} /> PASSED</span></div>
        <div className="pa-cert-meta"><div><span>BATCH</span><b>#IC-0426</b></div><div><span>MILLED</span><b>17 Nov 2026</b></div><div><span>PEAK TEMP</span><b>27.4°C</b></div></div>
        {labTests.map((t) => <div className="pa-cert-row" key={t.test}><span><Check size={11} /></span><div><strong>{t.test}</strong><small>{t.method}</small></div><b>{t.result}</b></div>)}
        <div className="pa-cert-foot"><BadgeCheck size={14} /> 6 of 6 parameters passed · nothing added</div>
      </div>
      <div className="pa-section-head"><div><span className="pa-eyebrow">OUR STANDARDS</span><h2 className="display">Quality benchmarks</h2></div></div>
      <div className="pa-benchmarks">{benchmarks.map((b, i) => <div className="pa-benchmark" key={b.title}><span>{String(i + 1).padStart(2, '0')}</span><div><strong>{b.title}</strong><small>{b.note}</small></div><code>{b.code}</code></div>)}</div>
      <div className="pa-verify"><div className="pa-qr">{Array.from({ length: 49 }, (_, i) => <i key={i} className={((i * 7 + Math.floor(i / 7) * 3) % 5 < 2) ? 'on' : ''} />)}<b><Wheat size={13} /></b></div><div><span className="pa-eyebrow">VERIFY YOUR PACK</span><strong>Scan the code on your sack</strong><p>See milling temperature, lab results and farm of origin.</p></div></div>
      <div className="pa-foot-note"><ShieldCheck size={14} /> Lab-tested, every single batch</div>
    </>
  )

  /* ---------- CART ---------- */
  const CartScreen = () => (
    <>
      <AppBar title="Your basket" sub={`${cartCount} item${cartCount === 1 ? '' : 's'}`} right={<button className="pa-round" onClick={() => goTab('shop')} aria-label="Shop"><Plus size={17} /></button>} />
      {cart.length === 0 ? (
        <div className="pa-cart-empty"><span><ShoppingBag size={30} /></span><strong>Your basket is empty</strong><p>Good flour makes better rotis. Start with our bestsellers.</p><button className="pa-primary" onClick={() => goTab('shop')}>Explore attas <ArrowRight size={15} /></button></div>
      ) : (
        <>
          <div className="pa-ship"><span>{shipLeft > 0 ? `Add ${money(shipLeft)} more for free shipping` : 'Free shipping unlocked!'}</span><div><i style={{ width: `${Math.min(100, subtotal / 499 * 100)}%` }} /></div></div>
          <div className="pa-cart-list">
            {cart.map((l) => (
              <div className="pa-cart-line" key={l.key}>
                <div className="pa-cart-img tone-sand"><Pack src={l.image} /></div>
                <div className="pa-cart-info"><strong>{l.name}</strong><small>{l.size}</small><div className="pa-qty"><button onClick={() => setCart((c) => c.map((x) => x.key === l.key ? { ...x, qty: Math.max(0, x.qty - 1) } : x).filter((x) => x.qty > 0))}><Minus size={12} /></button><span>{l.qty}</span><button onClick={() => setCart((c) => c.map((x) => x.key === l.key ? { ...x, qty: x.qty + 1 } : x))}><Plus size={12} /></button></div></div>
                <div className="pa-cart-right"><b>{money(l.price * l.qty)}</b><button onClick={() => setCart((c) => c.filter((x) => x.key !== l.key))} aria-label="Remove"><Trash2 size={14} /></button></div>
              </div>
            ))}
          </div>
          <div className="pa-coupon"><span><Sparkles size={14} /></span><input value={coupon} onChange={(e) => { setCoupon(e.target.value.toUpperCase()); setCouponApplied(false) }} placeholder="Coupon code" /><button onClick={() => { if (coupon.trim() === 'CLEAR50') { setCouponApplied(true); showToast('CLEAR50 applied · ₹50 off') } else showToast('Invalid code — try CLEAR50') }}>{couponApplied ? 'Applied' : 'Apply'}</button></div>
          {couponApplied && <div className="pa-coupon-ok"><CheckCircle2 size={13} /> ₹50 discount applied</div>}
          <div className="pa-bill"><div><span>Subtotal</span><b>{money(subtotal)}</b></div><div><span>You save</span><b className="green">− {money(savings + discount)}</b></div><div><span>Delivery</span><b>{shipping ? money(shipping) : 'FREE'}</b></div><div className="pa-bill-total"><span>Total</span><b>{money(total)}</b></div></div>
          <button className="pa-primary pa-checkout" onClick={() => goScreen('checkout')}>Proceed to checkout · {money(total)} <ArrowRight size={16} /></button>
          <div className="pa-foot-note"><ShieldCheck size={14} /> Secure checkout · 100% purity guaranteed</div>
        </>
      )}
    </>
  )

  /* ---------- CHECKOUT ---------- */
  const CheckoutScreen = () => (
    <div className="pa-checkout">
      <AppBar title="Checkout" sub="Step 1 of 1 · UI demo" back right={<button className="pa-round" onClick={() => showToast('Need help? hello@itsclear.in')} aria-label="Help"><HelpCircle size={17} /></button>} />
      <div className="pa-stepper"><span className="on">Basket</span><i /><span className="on">Checkout</span><i /><span>Confirm</span></div>
      <div className="pa-checkout-card">
        <div className="pa-checkout-head"><MapPin size={17} /><strong>Delivery address</strong><button onClick={() => showToast('Address saved')}>Edit</button></div>
        <div className="pa-field"><label>Full name</label><input value={address.name} onChange={(e) => setAddress({ ...address, name: e.target.value })} /></div>
        <div className="pa-field-row"><div className="pa-field"><label>Phone</label><input value={address.phone} onChange={(e) => setAddress({ ...address, phone: e.target.value })} /></div><div className="pa-field"><label>Pincode</label><input value={address.pin} onChange={(e) => setAddress({ ...address, pin: e.target.value })} /></div></div>
        <div className="pa-field"><label>Flat / house no.</label><input value={address.line} onChange={(e) => setAddress({ ...address, line: e.target.value })} /></div>
        <div className="pa-field"><label>City & state</label><input value={address.city} onChange={(e) => setAddress({ ...address, city: e.target.value })} /></div>
      </div>
      <div className="pa-checkout-card">
        <div className="pa-checkout-head"><Truck size={17} /><strong>Delivery slot</strong></div>
        <div className="pa-slot-row">{[['2-hour EV', '~94 mins'], ['Tomorrow', '9 AM – 1 PM'], ['Scheduled', 'Pick a day']].map(([t, s]) => <button key={t} className={slot === t ? 'on' : ''} onClick={() => setSlot(t)}><b>{t}</b><small>{s}</small></button>)}</div>
      </div>
      <div className="pa-checkout-card">
        <div className="pa-checkout-head"><Wallet size={17} /><strong>Payment method</strong></div>
        <div className="pa-pay-list">{[['UPI', 'GPay · PhonePe · Paytm', CreditCard], ['Card', 'Credit / debit card', CreditCard], ['Cash', 'Pay on delivery', Package]].map(([t, s, I]) => (
          <button key={t} className={payment === t ? 'on' : ''} onClick={() => setPayment(t)}><span><I size={16} /></span><div><strong>{t}</strong><small>{s}</small></div><i>{payment === t && <Check size={12} />}</i></button>
        ))}</div>
      </div>
      <div className="pa-checkout-secure"><ShieldCheck size={15} /><span>Your details stay on this device · UI demo only</span></div>
      <div className="pa-checkout-summary"><div><span>Items</span><b>{money(subtotal)}</b></div><div><span>Delivery</span><b>{shipping ? money(shipping) : 'FREE'}</b></div><div><span>Coupon</span><b className="green">{discount ? `− ${money(discount)}` : '—'}</b></div><div className="pa-checkout-total"><span>Total payable</span><b>{money(total)}</b></div></div>
      <button className="pa-primary pa-checkout-place" onClick={() => { orderId.current = `IC${Math.floor(10000 + Math.random() * 89999)}`; setOrderIds((o) => [orderId.current, ...o]); goScreen('order') }}>Place order · {money(total)} <ArrowRight size={16} /></button>
      <div className="pa-foot-note"><ShieldCheck size={14} /> No payment is processed · UI only</div>
    </div>
  )

  /* ---------- PROFILE ---------- */
  const ProfileScreen = () => (
    <>
      <AppBar title="My account" sub="Verified member" right={<button className="pa-round" onClick={() => goScreen('notifications')} aria-label="Notifications"><BellRing size={17} /></button>} />
      <div className="pa-profile-card"><span className="pa-avatar">AS</span><div><strong>Aarav Sharma</strong><small>aarav.sharma@email.com</small><span><BadgeCheck size={11} /> Verified buyer since 2024</span></div><span className="pa-member-badge">GOLD MEMBER</span></div>
      <div className="pa-profile-stats"><div><b>{orderIds.length + 9}</b><span>Orders</span></div><div><b>{wish.length}</b><span>Saved</span></div><div><b>84 kg</b><span>Flour</span></div></div>
      <div className="pa-menu">
        {[
          [Package, 'My orders', `${orderIds.length} recent deliveries`, () => goScreen('orders')],
          [Heart, 'Saved items', `${wish.length} flours`, () => goScreen('wishlist')],
          [BellRing, 'Notifications', 'Harvest & delivery updates', () => goScreen('notifications')],
          [Gift, 'Offers & coupons', 'CLEAR50 · up to 25% off', () => goScreen('offers')],
          [MapPin, 'Delivery addresses', `Home · ${pin}`, () => goScreen('checkout')],
          [FileText, 'Lab certificates', 'Batch #IC-0426', () => goTab('lab')],
          [HelpCircle, 'Help & FAQ', 'Cold milling, delivery', () => showToast('FAQ · hello@itsclear.in')],
          [ArrowUpRight, 'Desktop website', 'Open the full storefront', () => { window.location.href = '?web=1' }],
        ].map(([I, t, s, fn]) => (
          <button className="pa-menu-row" key={t} onClick={fn}><span><I size={17} /></span><div><strong>{t}</strong><small>{s}</small></div><ChevronRight size={15} /></button>
        ))}
      </div>
      <div className="pa-review-mini"><span className="pa-eyebrow">FROM OUR KITCHENS</span><Stars value={5} /><p>“{testimonials[0].quote.slice(0, 108)}…”</p><small>— {testimonials[0].name}</small></div>
      <div className="pa-foot-note"><Wheat size={14} /> itsclear™ · v2.0 · UI demo</div>
    </>
  )

  /* ---------- SEARCH ---------- */
  const SearchScreen = () => (
    <div className="pa-search-screen">
      <div className="pa-search-top"><button className="pa-round" onClick={goBack} aria-label="Back"><ArrowLeft size={17} /></button><div className="pa-search-input"><Search size={16} /><input autoFocus value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search attas, bundles…" />{query && <button onClick={() => setQuery('')} aria-label="Clear"><X size={15} /></button>}</div></div>
      <span className="pa-eyebrow">{query ? `${results.length} RESULTS` : 'POPULAR SEARCHES'}</span>
      <div className="pa-search-results">{results.map((p) => (
        <button key={p.id} onClick={() => { const full = products.find((x) => x.id === p.id); full ? openProduct(full) : goTab('shop') }}><Pack src={p.image} /><div><strong>{p.name}</strong><small>{p.subtitle}</small></div><b>{money(p.sizes[0].price)}</b></button>
      ))}</div>
      {results.length === 0 && <p className="pa-noresults">No matches. Try “khapli” or “protein”.</p>}
      <div className="pa-tags">{['Khapli', 'High Protein', '10 kg', 'Bundles'].map((t) => <button key={t} onClick={() => setQuery(t)}>{t}</button>)}</div>
    </div>
  )

  /* ---------- PRODUCT ---------- */
  const ProductScreen = () => !active ? null : (
    <div className="pa-detail">
      <div className="pa-detail-bar"><button className="pa-round" onClick={goBack} aria-label="Back"><ArrowLeft size={17} /></button><strong>Product details</strong><button className={`pa-round ${wish.includes(active.id) ? 'on' : ''}`} onClick={() => toggleWish(active.id)} aria-label="Save"><Heart size={16} fill={wish.includes(active.id) ? 'currentColor' : 'none'} /></button></div>
      <div className={`pa-detail-media tone-${active.tone}`}>
        <Pack src={gallery[photo]} alt={active.name} />
        <span className="pa-tag">{active.tag}</span>
        <span className="pa-detail-temp"><Thermometer size={12} /> Milled below 28°C</span>
        <button className="pa-gallery-prev" onClick={() => setPhoto((i) => (i - 1 + gallery.length) % gallery.length)} aria-label="Previous"><ChevronLeft size={17} /></button>
        <button className="pa-gallery-next" onClick={() => setPhoto((i) => (i + 1) % gallery.length)} aria-label="Next"><ChevronRight size={17} /></button>
      </div>
      <div className="pa-gallery-dots">{gallery.map((g, i) => <button key={g} className={photo === i ? 'on' : ''} onClick={() => setPhoto(i)} />)}</div>
      <div className="pa-detail-body">
        <span className="pa-origin"><MapPin size={11} /> {active.origin}</span>
        <h1 className="display">{active.name}</h1>
        <p>{active.subtitle}</p>
        <div className="pa-detail-rating"><Stars value={active.rating} /><span>{active.rating.toFixed(1)} <em>({active.reviews} verified reviews)</em></span></div>
        <div className="pa-detail-price"><b>{money(size.price)}</b><s>{money(size.mrp)}</s><span>Save {money(size.mrp - size.price)}</span></div>
        <span className="pa-eyebrow">CHOOSE PACK SIZE</span>
        <div className="pa-sizes">{active.sizes.map((s, i) => <button key={s.label} className={sizeIdx === i ? 'on' : ''} onClick={() => setSizeIdx(i)}>{s.label}</button>)}</div>
        <div className="pa-facts">{[['< 28°C', 'Cold milled'], ['72%', 'Water absorption'], ['100%', 'Bran retained'], ['36', 'Rotis / kg']].map(([b, s]) => <div key={s}><b>{b}</b><span>{s}</span></div>)}</div>
        <div className="pa-detail-tabs">{[['overview', 'Overview'], ['nutrition', 'Nutrition'], ['lab', 'Lab report']].map(([k, l]) => <button key={k} className={detailTab === k ? 'on' : ''} onClick={() => setDetailTab(k)}>{l}</button>)}</div>
        {detailTab === 'overview' && <p className="pa-tab-text">Triple-washed heritage grain from {active.origin}, ground slowly on emery stone chakkis that never exceed 28°C. Live enzymes, natural germ oils and coarse fibre stay intact. No maida, no bleach, no preservatives — with a batch purity certificate in every pack.</p>}
        {detailTab === 'nutrition' && <div className="pa-nutri">{nutrition.map((n) => <div key={n.label}><span>{n.label}</span><b>{n.value}</b></div>)}</div>}
        {detailTab === 'lab' && <div className="pa-nutri">{labTests.slice(0, 4).map((t) => <div key={t.test}><span>{t.test}</span><b>{t.result}</b></div>)}<button className="pa-link" onClick={() => goTab('lab')}>Full certificate <ArrowUpRight size={13} /></button></div>}
        <div className="pa-section-head"><div><span className="pa-eyebrow">YOU MAY ALSO LIKE</span><h2 className="display">More from the harvest</h2></div></div>
        <div className="pa-rail">{products.filter((p) => p.id !== active.id).slice(0, 3).map((p) => <ProductCard key={p.id} p={p} compact />)}</div>
      </div>
      <div className="pa-detail-buy"><div className="pa-qty pa-qty--lg"><button onClick={() => setQty((q) => Math.max(1, q - 1))}><Minus size={14} /></button><span>{qty}</span><button onClick={() => setQty((q) => q + 1)}><Plus size={14} /></button></div><button className="pa-primary" onClick={() => { addItem({ id: active.id, name: active.name, image: active.image, size: size.label, price: size.price, mrp: size.mrp, qty }); goTab('cart') }}>Add · {money(size.price * qty)} <ArrowRight size={15} /></button></div>
    </div>
  )

  /* ---------- CALCULATOR ---------- */
  const CalcScreen = () => (
    <div className="pa-sheet">
      <div className="pa-sheet-bar"><div /><button className="pa-round" onClick={goBack} aria-label="Close"><X size={17} /></button></div>
      <span className="pa-eyebrow">GRAIN SCIENCE</span><h2 className="display">How many rotis does <em>your</em> family need?</h2>
      <p>itsclear absorbs 72% water — 36 soft rotis per kg instead of 28 from factory flour.</p>
      <span className="pa-eyebrow">FAMILY MEMBERS</span>
      <div className="pa-chips">{[2, 4, 6, 8].map((m) => <button key={m} className={members === m ? 'on' : ''} onClick={() => { setMembers(m); setRotis(Math.max(4, m * 4)) }}>{m} Members</button>)}</div>
      <span className="pa-eyebrow">ROTIS PER DAY</span>
      <input className="pa-range" type="range" min="4" max="60" value={rotis} onChange={(e) => setRotis(+e.target.value)} style={{ '--fill': `${(rotis - 4) / 56 * 100}%` }} />
      <div className="pa-chips">{[['Light', 4], ['Average', 16], ['Large', 40]].map(([l, v]) => <button key={l} className={rotis === v ? 'on' : ''} onClick={() => setRotis(v)}>{l} ({v})</button>)}</div>
      <div className="pa-calc-result"><span>MONTHLY PROJECTION</span><strong>{monthly} <small>rotis / month</small></strong><div><span>itsclear</span><i style={{ '--w': `${(clearKg / factoryKg * 100).toFixed(0)}%` }} /><b>{clearKg.toFixed(1)} kg</b></div><div><span>Factory atta</span><i className="alt" style={{ '--w': '100%' }} /><b>{factoryKg.toFixed(1)} kg</b></div><p><Sparkles size={14} /> You save <b>{savedKg} kg</b> of flour every month.</p></div>
      <button className="pa-primary" onClick={() => { setFilter('All'); goTab('shop') }}>Shop the recommended pack <ArrowRight size={15} /></button>
    </div>
  )

  /* ---------- 360° VIEWER ---------- */
  const ViewerScreen = () => {
    const down = (e) => { viewerDrag.current = { x: e.clientX, a: viewerAngle } }
    const move = (e) => { if (!viewerDrag.current) return; setViewerAngle(viewerDrag.current.a + (e.clientX - viewerDrag.current.x) * .6) }
    const up = () => { viewerDrag.current = null }
    return (
      <div className="pa-viewer">
        <AppBar title="360° pack inspector" sub="Authentic itsclear™ packaging" back right={<button className="pa-round" onClick={() => { setViewerAngle(0); setViewerIdx(0) }} aria-label="Reset"><RotateCcw size={16} /></button>} />
        <div className="pa-viewer-stage" onPointerDown={down} onPointerMove={move} onPointerUp={up} onPointerCancel={up}>
          <span className="pa-viewer-angle">{String(Math.abs(Math.round(viewerAngle) % 360)).padStart(3, '0')}°</span>
          <Pack src={VIEWER_PACKS[viewerIdx]} className="pa-viewer-pack" style={{ transform: `perspective(900px) rotateY(${Math.sin(viewerAngle * Math.PI / 180) * 18}deg)` }} />
          <span className="pa-viewer-hint">Drag left or right to inspect the pouch</span>
        </div>
        <div className="pa-viewer-tabs">{[['Front', 0], ['Handle', 5], ['Range', 2]].map(([l, i]) => <button key={l} className={viewerIdx === i ? 'on' : ''} onClick={() => { setViewerIdx(i); setViewerAngle(0) }}>{l}</button>)}</div>
        <div className="pa-viewer-film">{VIEWER_PACKS.map((p, i) => <button key={p} className={viewerIdx === i ? 'on' : ''} onClick={() => { setViewerIdx(i); setViewerAngle(0) }}><Pack src={p} /></button>)}</div>
        <div className="pa-viewer-spec"><Thermometer size={15} /><div><strong>Cold milled below 28°C</strong><small>100% Khapli Wheat · Batch #IC-0426</small></div><BadgeCheck size={17} /></div>
        <div className="pa-viewer-specs"><div><b>27.4°C</b><span>Peak temp</span></div><div><b>0.00</b><span>Bleach ppm</span></div><div><b>100%</b><span>Bran kept</span></div></div>
      </div>
    )
  }

  /* ---------- WISHLIST ---------- */
  const WishlistScreen = () => {
    const items = products.filter((p) => wish.includes(p.id))
    return (
      <div className="pa-list-screen">
        <AppBar title="Saved items" sub={`${items.length} flours`} back right={<button className="pa-round" onClick={openSearch} aria-label="Search"><Search size={17} /></button>} />
        {items.length === 0 ? <div className="pa-cart-empty"><span><Heart size={30} /></span><strong>Nothing saved yet</strong><p>Tap the heart on any pack to keep it here.</p><button className="pa-primary" onClick={() => goTab('shop')}>Browse attas <ArrowRight size={15} /></button></div> :
          <div className="pa-wish-list">{items.map((p) => (
            <div className="pa-wish-row" key={p.id}><div className="pa-wish-img tone-sand"><Pack src={p.image} /></div><div><strong>{p.name}</strong><small>{p.subtitle}</small><b>{money(p.sizes[0].price)}</b></div><button onClick={() => addItem({ id: p.id, name: p.name, image: p.image, size: p.sizes[0].label, price: p.sizes[0].price, mrp: p.sizes[0].mrp, qty: 1 })}><Plus size={15} /></button><button className="pa-wish-remove" onClick={() => toggleWish(p.id)}><X size={14} /></button></div>
          ))}</div>}
        <div className="pa-foot-note"><Heart size={14} /> Saved locally in this UI demo</div>
      </div>
    )
  }

  /* ---------- ORDERS ---------- */
  const OrdersScreen = () => (
    <div className="pa-list-screen">
      <AppBar title="My orders" sub={`${orderIds.length} recent orders`} back />
      <div className="pa-orders">{orderIds.map((id, i) => (
        <div className="pa-order-row" key={id}><div className="pa-order-row-icon"><PackageCheck size={19} /></div><div><strong>Order #{id}</strong><small>{i === 0 ? 'Freshly packed · EV van assigned' : 'Delivered · 100% purity guaranteed'}</small><span>{i === 0 ? 'Arriving in ~94 mins' : ['12 Nov 2026', '28 Oct 2026', '09 Oct 2026'][i - 1] || 'Oct 2026'}</span></div><button onClick={() => goScreen('tracking')}>Track <ChevronRight size={14} /></button></div>
      ))}</div>
      <div className="pa-foot-note"><ClipboardList size={14} /> Order history is UI-only</div>
    </div>
  )

  /* ---------- TRACKING ---------- */
  const TrackingScreen = () => (
    <div className="pa-list-screen pa-track-screen">
      <AppBar title="Track order" sub={`#${orderId.current}`} back />
      <div className="pa-track-hero"><span className="pa-track-icon"><Navigation size={24} /></span><div><span className="pa-eyebrow">EXPRESS EV DELIVERY</span><strong>Arriving in ~94 mins</strong><small>Climate-controlled van · Lucknow 226001</small></div></div>
      <div className="pa-timeline">
        {[['Order confirmed', 'Just now', true], ['Stone-milled & packed', 'Batch #IC-0426', true], ['Picked up by EV van', '12 min ago', true], ['Out for delivery', 'Arriving ~94 mins', false], ['Delivered to your door', 'Pending', false]].map(([t, s, done]) => (
          <div className={`pa-timeline-row ${done ? 'done' : ''}`} key={t}><span>{done ? <Check size={12} /> : ''}</span><div><strong>{t}</strong><small>{s}</small></div></div>
        ))}
      </div>
      <button className="pa-primary" onClick={() => { setCart([]); setCouponApplied(false); setCoupon(''); goTab('home') }}>Back to home <ArrowRight size={15} /></button>
    </div>
  )

  /* ---------- NOTIFICATIONS ---------- */
  const NotificationsScreen = () => (
    <div className="pa-list-screen">
      <AppBar title="Notifications" sub="Harvest & delivery updates" back />
      <div className="pa-notif-toggle"><div><BellRing size={18} /><span><strong>Push notifications</strong><small>New batches, offers and delivery status</small></span></div><button className={`pa-switch ${notif ? 'on' : ''}`} onClick={() => setNotif((v) => !v)}><i /></button></div>
      <div className="pa-notif-list">{NOTIFICATIONS.map((n, i) => <div className="pa-notif-row" key={n.title}><span><n.icon size={17} /></span><div><strong>{n.title}</strong><small>{n.text}</small><em>{n.time}</em></div>{i === 0 && <i className="pa-notif-dot" />}</div>)}</div>
      <div className="pa-foot-note"><Bell size={14} /> Nothing is sent from this UI demo</div>
    </div>
  )

  /* ---------- OFFERS ---------- */
  const OffersScreen = () => (
    <div className="pa-list-screen">
      <AppBar title="Offers & coupons" sub="Harvest savings" back />
      <div className="pa-offer-hero"><TicketPercent size={26} /><div><span className="pa-eyebrow pa-eyebrow--light">LIMITED HARVEST OFFER</span><strong>Up to 25% off</strong><small>On selected 5kg and 10kg stoneground packs</small></div></div>
      <div className="pa-offer-card"><div><span className="pa-eyebrow">CODE · CLEAR50</span><strong>₹50 off your basket</strong><small>Valid on orders above ₹499 · UI demo</small></div><button onClick={() => { setCoupon('CLEAR50'); showToast('CLEAR50 copied'); navigator.clipboard?.writeText('CLEAR50') }}><Copy size={14} /> Copy</button></div>
      <div className="pa-offer-card"><div><span className="pa-eyebrow">FREE DELIVERY</span><strong>On orders over ₹499</strong><small>2-hour EV delivery in supported pincodes</small></div><Truck size={20} /></div>
      <div className="pa-offer-card"><div><span className="pa-eyebrow">BUNDLE VALUE</span><strong>Save up to ₹250</strong><small>Family, fitness and ancient-grain monthly kits</small></div><Gift size={20} /></div>
      <button className="pa-primary" onClick={() => goTab('shop')}>Shop the offers <ArrowRight size={15} /></button>
    </div>
  )

  /* ---------- ORDER SUCCESS ---------- */
  const OrderScreen = () => (
    <div className="pa-order"><div className="pa-order-icon"><PackageCheck size={38} /></div><div className="pa-order-progress"><span className="on">Confirmed</span><i /><span className="on">Packed</span><i /><span>On the way</span></div><span className="pa-eyebrow">ORDER CONFIRMED</span><h1 className="display">Fresh flour is <em>on its way.</em></h1><p>Order <b>#{orderId.current}</b> is being packed. Stone-milled within 24h and heading to you in a climate-controlled EV van.</p><div className="pa-order-card"><div><Truck size={17} /><span>Express EV delivery</span><b>~94 mins</b></div><div><MapPin size={17} /><span>Delivering to</span><b>{address.pin}</b></div><div><ShieldCheck size={17} /><span>Batch certificate</span><b>#IC-0426</b></div></div><button className="pa-primary" onClick={() => { setCart([]); setCouponApplied(false); setCoupon(''); goTab('home') }}>Back to home <ArrowRight size={16} /></button><button className="pa-link" onClick={() => goScreen('tracking')}>Track my order <ArrowUpRight size={13} /></button></div>
  )

  const showTabBar = screen === null
  const hero = HEROES[heroIdx]

  return (
    <div className="pa-stage">
      <div className="pa-stage-glow" />
      <div className="pa-side-note"><span className="pa-eyebrow pa-eyebrow--light">itsclear™ · FULL ECOMMERCE APP UI</span><h2 className="display">The honest atta store, <em>in your pocket.</em></h2><p>A premium native-style shopping app: quick actions, editorial stories, 360° pack inspector, verified lab certificate, Basket, Checkout, Orders, Wishlist, Offers and Profile — built around the exact black-and-cream packaging from the reference site.</p><a href="?web=1">View desktop site <ArrowUpRight size={14} /></a></div>
      <div className="pa-device">
        <div className="pa-island" />
        <div className="pa-status"><span>9:41</span><div><span className="pa-signal">▮▮▮</span><span className="pa-wifi">◕</span><span className="pa-battery" /></div></div>
        <div className="pa-scroll" ref={scrollRef} key={`${screen || 'tab'}-${tab}`}>
          {screen === 'product' ? <ProductScreen /> : screen === 'search' ? <SearchScreen /> : screen === 'calc' ? <CalcScreen /> :
            screen === 'checkout' ? <CheckoutScreen /> : screen === 'order' ? <OrderScreen /> :
            screen === 'viewer' ? <ViewerScreen /> : screen === 'wishlist' ? <WishlistScreen /> :
            screen === 'orders' ? <OrdersScreen /> : screen === 'tracking' ? <TrackingScreen /> :
            screen === 'notifications' ? <NotificationsScreen /> : screen === 'offers' ? <OffersScreen /> :
            tab === 'home' ? <HomeScreen /> : tab === 'shop' ? <ShopScreen /> : tab === 'lab' ? <LabScreen /> :
            tab === 'cart' ? <CartScreen /> : <ProfileScreen />}
        </div>
        {showTabBar && (
          <nav className="pa-tabbar">
            {TABS.map((t) => (
              <button key={t.id} className={tab === t.id ? 'on' : ''} onClick={() => goTab(t.id)}>
                <span className="pa-tab-icon"><t.icon size={19} strokeWidth={1.8} />{t.id === 'cart' && cartCount > 0 && <i>{cartCount}</i>}</span><small>{t.label}</small>
              </button>
            ))}
          </nav>
        )}
        {toast && <div className="pa-toast" key={toast.id}><CheckCircle2 size={15} />{toast.msg}</div>}
      </div>
      <div className="pa-hint">Tap around · bottom tabs + full checkout flow · try <b>CLEAR50</b> in the basket</div>
    </div>
  )
}
