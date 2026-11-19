import { useEffect, useMemo, useRef, useState } from 'react'
import {
  ArrowRight, ArrowUpRight, Award, BadgeCheck, Check, CheckCircle2, ChevronDown,
  ChevronLeft, ChevronRight, Clock, Copy, Droplets, FlaskConical, Heart, Leaf,
  MapPin, Menu, Minus, MoveHorizontal, PackageCheck, Plus, Quote, RotateCcw,
  Search, ShieldCheck, ShoppingBag, Sparkles, Star, Sprout, Thermometer,
  Trash2, Truck, Wheat, X, Zap, Instagram, Facebook, Mail, Send,
} from 'lucide-react'
import {
  IMG, categories, products, bundles, ranked, comparison, faqs,
  testimonials, certifications, heroSlides,
} from './data.js'
import { CatalogView, ProductView, LabSection } from './Views.jsx'
import CheckoutView from './CheckoutView.jsx'

const money = (n) => `₹${Number(n).toLocaleString('en-IN')}`
/* App registers a handler so section links work from the catalog / product views too. */
const scrollTo = (id) => {
  if (typeof window !== 'undefined' && window.__itsclearGo) window.__itsclearGo(id)
  else document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function Stars({ value, small = false }) {
  return (
    <span className={`stars ${small ? 'stars--sm' : ''}`} aria-label={`${value} out of 5`}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Star key={i} size={small ? 11 : 13} fill={i <= Math.round(value) ? 'currentColor' : 'none'} strokeWidth={1.6} />
      ))}
    </span>
  )
}

function Eyebrow({ children, light = false }) {
  return <div className={`eyebrow ${light ? 'eyebrow--light' : ''}`}><span className="eyebrow-dot" />{children}</div>
}

function SectionHead({ eyebrow, title, desc, action, onAction, light = false, center = false }) {
  return (
    <div className={`section-head ${center ? 'section-head--center' : ''}`}>
      <div>
        <Eyebrow light={light}>{eyebrow}</Eyebrow>
        <h2 className="display">{title}</h2>
        {desc && <p className="section-desc">{desc}</p>}
      </div>
      {action && (
        <button className="text-link" onClick={onAction}>
          {action} <ArrowUpRight size={16} />
        </button>
      )}
    </div>
  )
}

export default function App() {
  const [cart, setCart] = useState([])
  const [cartOpen, setCartOpen] = useState(false)
  const [searchOpen, setSearchOpen] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)
  const [toast, setToast] = useState(null)
  const [wishlist, setWishlist] = useState([])
  const [filter, setFilter] = useState('All')
  const [sizes, setSizes] = useState({})
  const [heroSize, setHeroSize] = useState(1)
  const [angle, setAngle] = useState(0)
  const [dragging, setDragging] = useState(false)
  const [quickView, setQuickView] = useState(null)
  const [pin, setPin] = useState('')
  const [pinResult, setPinResult] = useState(null)
  const [email, setEmail] = useState('')
  const [subbed, setSubbed] = useState(false)
  const [faqOpen, setFaqOpen] = useState(0)
  const [tIndex, setTIndex] = useState(0)
  const [copied, setCopied] = useState(false)
  const [query, setQuery] = useState('')
  const [scrolled, setScrolled] = useState(false)
  const [orderPlaced, setOrderPlaced] = useState(false)
  const [members, setMembers] = useState(4)
  const [rotis, setRotis] = useState(16)
  const [view, setView] = useState('home')            // home | catalog | product | checkout
  const [activeProduct, setActiveProduct] = useState(null)
  const [slide, setSlide] = useState(0)
  const toastTimer = useRef(null)
  const drag = useRef({ active: false, startX: 0, startAngle: 0 })
  const deadline = useRef(Date.now() + ((2 * 24 + 14) * 3600 + 37 * 60 + 11) * 1000)
  const viewRef = useRef('home')

  const heroSlide = heroSlides[slide]
  const heroPacks = heroSlide.packs
  const packIndex = Math.min(heroSize, heroPacks.length - 1)
  const pack = heroPacks[packIndex]

  const goView = (next, product = null) => {
    if (product) setActiveProduct(product)
    setView(next)
    setCartOpen(false); setSearchOpen(false); setMenuOpen(false); setQuickView(null)
    window.scrollTo({ top: 0, behavior: 'auto' })
  }
  const selectSlide = (i) => { setSlide(i); setHeroSize(1); setAngle(0) }
  const placeOrder = () => {
    setCart([]); setOrderPlaced(true); setView('home')
    setSearchOpen(false); setMenuOpen(false); setQuickView(null)
    window.scrollTo({ top: 0, behavior: 'auto' })
    setCartOpen(true)
  }

  /* ---------- effects ---------- */
  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24)
    window.addEventListener('scroll', onScroll, { passive: true })
    return () => window.removeEventListener('scroll', onScroll)
  }, [])

  useEffect(() => {
    const io = new IntersectionObserver(
      (entries) => entries.forEach((e) => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target) } }),
      { threshold: 0.08, rootMargin: '0px 0px -40px 0px' }
    )
    document.querySelectorAll('.reveal').forEach((el) => { if (!el.classList.contains('in')) io.observe(el) })
    return () => io.disconnect()
  }, [view, activeProduct])

  useEffect(() => { viewRef.current = view }, [view])
  useEffect(() => {
    window.__itsclearGo = (id) => {
      if (viewRef.current !== 'home') {
        setView('home')
        setTimeout(() => document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 110)
      } else {
        document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }
    return () => { delete window.__itsclearGo }
  }, [])

  const [clock, setClock] = useState({ d: '02', h: '14', m: '37', s: '11' })
  useEffect(() => {
    const pad = (n) => String(Math.max(0, n)).padStart(2, '0')
    const tick = () => {
      const diff = Math.max(0, deadline.current - Date.now())
      const total = Math.floor(diff / 1000)
      setClock({ d: pad(Math.floor(total / 86400)), h: pad(Math.floor(total / 3600) % 24), m: pad(Math.floor(total / 60) % 60), s: pad(total % 60) })
    }
    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [])

  useEffect(() => {
    const onKey = (e) => {
      if (e.key === 'Escape') { setCartOpen(false); setSearchOpen(false); setMenuOpen(false); setQuickView(null) }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  const anyOverlay = cartOpen || searchOpen || menuOpen || !!quickView
  useEffect(() => {
    document.body.style.overflow = anyOverlay ? 'hidden' : ''
    return () => { document.body.style.overflow = '' }
  }, [anyOverlay])

  /* ---------- helpers ---------- */
  const showToast = (msg, action) => {
    clearTimeout(toastTimer.current)
    setToast({ msg, action, id: Date.now() })
    toastTimer.current = setTimeout(() => setToast(null), 3600)
  }

  const addItem = (item, openDrawer = false) => {
    const key = `${item.id}__${item.size}`
    setCart((prev) => {
      const found = prev.find((l) => l.key === key)
      if (found) return prev.map((l) => l.key === key ? { ...l, qty: l.qty + 1 } : l)
      return [...prev, { ...item, key, qty: 1 }]
    })
    showToast(`${item.name} · ${item.size} added to your basket`, 'view')
    if (openDrawer) setCartOpen(true)
    setOrderPlaced(false)
  }

  const cartCount = cart.reduce((a, l) => a + l.qty, 0)
  const subtotal = cart.reduce((a, l) => a + l.qty * l.price, 0)
  const savings = cart.reduce((a, l) => a + l.qty * ((l.mrp || l.price) - l.price), 0)
  const shipLeft = Math.max(0, 499 - subtotal)
  const shipping = shipLeft > 0 ? 49 : 0
  const checkoutTotal = subtotal + shipping

  const filtered = useMemo(
    () => filter === 'All' ? products : products.filter((p) => p.groups.includes(filter)),
    [filter]
  )
  const searchResults = useMemo(() => {
    const q = query.trim().toLowerCase()
    if (!q) return products.slice(0, 4)
    return products.filter((p) => `${p.name} ${p.subtitle} ${p.origin}`.toLowerCase().includes(q))
  }, [query])

  const toggleWish = (id) => {
    setWishlist((w) => w.includes(id) ? w.filter((x) => x !== id) : [...w, id])
    showToast(wishlist.includes(id) ? 'Removed from your saved list' : 'Saved for later')
  }

  const copyCode = () => {
    navigator.clipboard?.writeText('CLEAR50').catch(() => {})
    setCopied(true)
    showToast('Code CLEAR50 copied to clipboard')
    setTimeout(() => setCopied(false), 2200)
  }

  const checkPin = (e) => {
    e.preventDefault()
    if (!/^\d{6}$/.test(pin)) { setPinResult({ ok: false, msg: 'Please enter a valid 6-digit pincode.' }); return }
    const eta = 70 + (pin.split('').reduce((a, d) => a + Number(d), 0) % 50)
    setPinResult({ ok: true, msg: `Yes! Express EV delivery is live in ${pin}. Estimated arrival in ~${eta} mins, milled fresh within 24h.` })
  }

  const subscribe = (e) => {
    e.preventDefault()
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) { showToast('Please enter a valid email address'); return }
    setSubbed(true)
    showToast('You’re on the list — welcome to the harvest!')
  }

  /* ---------- roti calculator ---------- */
  const monthlyRotis = rotis * 30
  const clearKgRaw = monthlyRotis / 36
  const factoryKgRaw = monthlyRotis / 28
  const clearKg = clearKgRaw.toFixed(1)
  const factoryKg = factoryKgRaw.toFixed(1)
  const savedKg = (factoryKgRaw - clearKgRaw).toFixed(1)
  const recommended = Number(clearKg) <= 6 ? { label: '5 kg Carry Handle', price: 440 } : { label: '10 kg Family Sack', price: 849 }

  /* ---------- 360 drag ---------- */
  const onDragStart = (e) => {
    drag.current = { active: true, startX: e.clientX, startAngle: angle }
    setDragging(true)
    e.currentTarget.setPointerCapture?.(e.pointerId)
  }
  const onDragMove = (e) => {
    if (!drag.current.active) return
    const dx = e.clientX - drag.current.startX
    setAngle(drag.current.startAngle + dx * 0.85)
    /* Drag far enough and the viewer spins to the next packaging shot, like the original. */
    if (Math.abs(dx) > 105) {
      const dir = dx > 0 ? -1 : 1
      setSlide((s) => (s + dir + heroSlides.length) % heroSlides.length)
      setHeroSize(1)
      setAngle(0)
      drag.current.startX = e.clientX
      drag.current.startAngle = 0
    }
  }
  const onDragEnd = () => { drag.current.active = false; setDragging(false) }
  const tilt = Math.sin(angle * Math.PI / 180) * 20
  const degrees = String(Math.abs(Math.round(angle) % 360)).padStart(3, '0')

  const navLinks = [
    { label: 'Shop', id: 'shop' }, { label: 'Categories', id: 'categories' },
    { label: 'Our Process', id: 'process' }, { label: 'Zero-Maida Lab', id: 'lab' },
    { label: 'Grain Science', id: 'science' }, { label: 'Reviews', id: 'reviews' },
    { label: 'FAQ', id: 'faq' },
  ]

  return (
    <div className="app">
      {/* ============ ANNOUNCEMENT ============ */}
      <div className="announce">
        <div className="announce-track">
          {[0, 1].map((k) => (
            <div className="announce-group" key={k} aria-hidden={k === 1}>
              <span><Wheat size={13} /> NEW HARVEST COLLECTION</span><span className="sep">✳</span>
              <span>100% COLD STONEGROUND BELOW 28°C</span><span className="sep">✳</span>
              <span>FREE SHIPPING OVER ₹499</span><span className="sep">✳</span>
              <span>TRIPLE-WASHED · ZERO MAIDA</span><span className="sep">✳</span>
            </div>
          ))}
        </div>
      </div>

      {/* ============ HEADER ============ */}
      <header className={`header ${scrolled ? 'header--scrolled' : ''}`}>
        <div className="container header-inner">
          <button className="icon-btn menu-btn" onClick={() => setMenuOpen(true)} aria-label="Open menu"><Menu size={21} /></button>
          <a className="brand" href="#top" onClick={(e) => { e.preventDefault(); goView('home') }}>
            <span className="brand-mark"><Wheat size={19} strokeWidth={1.8} /></span>
            <span className="brand-word">itsclear<span className="brand-tm">™</span></span>
          </a>
          <nav className="nav">
            {navLinks.map((n) => <button key={n.id} onClick={() => scrollTo(n.id)}>{n.label}</button>)}
          </nav>
          <div className="header-actions">
            <button className="icon-btn" onClick={() => setSearchOpen(true)} aria-label="Search"><Search size={19} /></button>
            <button className="icon-btn cart-btn" onClick={() => { setCartOpen(true); setOrderPlaced(false) }} aria-label="Open basket">
              <ShoppingBag size={19} />
              {cartCount > 0 && <span className="cart-count">{cartCount}</span>}
            </button>
            <button className="btn btn-dark btn-sm header-cta" onClick={() => scrollTo('shop')}>Shop now <ArrowUpRight size={15} /></button>
          </div>
        </div>
      </header>

      {/* ============ HOME PAGE ============ */}
      {view === 'home' && (
      <>
      {/* ============ HERO ============ */}
      <section className="hero" id="top">
        <div className="hero-grain" />
        <div className="container hero-grid">
          <div className="hero-copy">
            <div className="hero-pill">NEW HARVEST COLLECTION <span>•</span> 100% COLD STONEGROUND</div>
            <h1 className="display hero-title">Discover The<br />Purest <em>Chakki Atta</em><br />Online</h1>
            <p className="hero-desc">Shop 100% honest stoneground flours milled below 28°C at farm-direct prices. Triple-washed grains, 100% bran retention, zero maida, zero bleaching agents.</p>
            <div className="hero-actions">
              <button className="btn btn-dark" onClick={() => scrollTo('shop')}>Shop the harvest <ArrowRight size={17} /></button>
              <button className="btn btn-ghost" onClick={() => scrollTo('lab')}><FlaskConical size={16} /> The zero-maida lab</button>
            </div>
            <div className="hero-trust">
              <div className="hero-trust-item"><span className="mini-icon"><ShieldCheck size={17} /></span><div><strong>100% Purity</strong><small>Lab-tested every batch</small></div></div>
              <div className="hero-trust-item"><span className="mini-icon"><Thermometer size={17} /></span><div><strong>Cold Milled</strong><small>Never above 28°C</small></div></div>
              <div className="hero-trust-item"><span className="mini-icon"><Zap size={17} /></span><div><strong>2-Hour EV</strong><small>Fresh to your door</small></div></div>
            </div>
            <div className="social-proof">
              <div className="avatars"><span>MI</span><span>RS</span><span>AK</span><span>+10k</span></div>
              <div><Stars value={5} small /><small>Trusted by <strong>10,000+ households</strong> across India</small></div>
            </div>
          </div>

          <div className="hero-visual">
            <div className="viewer-card">
              <div className="viewer-top">
                <span className="viewer-label"><span className="live-dot" /> NEW HARVEST · BATCH #0426</span>
                <span className="viewer-top-right"><span className="viewer-count">{String(slide + 1).padStart(2, '0')} / 05</span><span className="viewer-degree">{degrees}°</span></span>
              </div>
              <div
                className={`viewer-stage ${dragging ? 'is-dragging' : ''}`}
                onPointerDown={onDragStart} onPointerMove={onDragMove}
                onPointerUp={onDragEnd} onPointerCancel={onDragEnd}
              >
                <div className="viewer-ring" style={{ transform: `rotate(${angle}deg)` }}><span /><span /><span /><span /></div>
                <div className="viewer-glow" />
                <img
                  key={heroSlide.id}
                  src={heroSlide.image} alt={`${heroSlide.name} — ${heroSlide.label}`}
                  className="viewer-bag viewer-bag--swap"
                  style={{ transform: `perspective(1100px) rotateY(${tilt}deg) rotateX(${Math.cos(angle * Math.PI / 180) * 2.5}deg) scale(${1 + Math.abs(tilt) / 400})` }}
                  draggable="false"
                />
                <span className="float-badge float-badge--a"><Thermometer size={14} /> &lt; 28°C <b>Cold milled</b></span>
                <span className="float-badge float-badge--b"><Leaf size={14} /> <b>{heroSlide.label}</b></span>
                <span className="float-badge float-badge--c"><BadgeCheck size={14} /> {heroSlide.spec}</span>
              </div>
              <div className="viewer-controls">
                <span className="drag-hint"><MoveHorizontal size={15} /> Drag 360° to inspect authentic packaging</span>
                <button onClick={() => { setAngle(0); setSlide(0); setHeroSize(1) }}><RotateCcw size={14} /> Reset</button>
              </div>
              <div className="viewer-filmstrip">
                {heroSlides.map((s, i) => (
                  <button key={s.id} className={`film ${i === slide ? 'film--active' : ''}`} onClick={() => selectSlide(i)} title={s.name}>
                    <img src={s.image} alt="" loading="lazy" />
                    <span><strong>{s.label}</strong><small>{s.spec}</small></span>
                  </button>
                ))}
              </div>
            </div>

            <div className="hero-purity-card">
              <span className="purity-icon"><ShieldCheck size={17} /></span>
              <div><small>PURITY SCORE</small><strong>98<span>/100</span></strong><em>6 of 6 lab tests passed</em></div>
              <div className="purity-bars"><i /><i /><i /><i /><i /></div>
            </div>

            <div className="hero-shop-card">
              <div className="hero-shop-head">
                <div><span className="tiny-label">FEATURED · {heroSlide.badge.toUpperCase()}</span><h3>{heroSlide.name}</h3></div>
                <div className="price-block"><strong>{money(pack.price)}</strong><s>{money(pack.mrp)}</s></div>
              </div>
              <div className="pack-row">
                {heroPacks.map((p, i) => (
                  <button key={p.label} className={`pack ${packIndex === i ? 'pack--active' : ''}`} onClick={() => setHeroSize(i)}>{p.label}</button>
                ))}
              </div>
              <div className="hero-shop-foot">
                <span className="ev-note"><CheckCircle2 size={15} /> Free 2-hour EV delivery</span>
                <button className="btn btn-dark btn-sm" onClick={() => addItem({ id: heroSlide.id, name: heroSlide.name, image: heroSlide.image, size: pack.label, price: pack.price, mrp: pack.mrp })}>
                  Add to basket <ArrowRight size={15} />
                </button>
              </div>
            </div>
          </div>
        </div>
        <div className="hero-bottom-line container">
          <span>01 / 06 — THE CLEAR STANDARD</span>
          <button onClick={() => scrollTo('trust')}>Scroll to explore <ChevronDown size={15} /></button>
          <span>100% WHOLE GRAIN · NOTHING ELSE</span>
        </div>
      </section>

      {/* ============ TRUST STRIP ============ */}
      <section className="trust" id="trust">
        <div className="container trust-grid">
          {[
            { icon: Truck, t: 'Free Shipping', s: 'On orders over ₹499' },
            { icon: ShieldCheck, t: '100% Purity', s: 'Zero maida guarantee' },
            { icon: Thermometer, t: 'Cold Stone Milled', s: 'Below 28°C, live enzymes' },
            { icon: RotateCcw, t: 'Freshness Promise', s: 'Milled within 24h of dispatch' },
          ].map((x) => (
            <div className="trust-item" key={x.t}>
              <span className="trust-icon"><x.icon size={21} strokeWidth={1.6} /></span>
              <div><strong>{x.t}</strong><small>{x.s}</small></div>
            </div>
          ))}
        </div>
      </section>

      {/* ============ CATEGORIES ============ */}
      <section className="section categories-section" id="categories">
        <div className="container">
          <div className="reveal"><SectionHead eyebrow="Find your flour" title="Shop by category" desc="One grain, many kitchens. Pick the mill that fits your family." action="View all products" onAction={() => goView('catalog')} /></div>
          <div className="cat-grid">
            {categories.map((c, i) => (
              <button className="cat-card reveal" key={c.name} style={{ animationDelay: `${i * 60}ms` }} onClick={() => { setFilter(c.filter); scrollTo('shop') }}>
                <div className="cat-img"><img src={c.image} alt={c.name} loading="lazy" /><span className="cat-arrow"><ArrowUpRight size={16} /></span></div>
                <div className="cat-text"><strong>{c.name}</strong><span>{c.note}</span></div>
              </button>
            ))}
          </div>
        </div>
      </section>

      {/* ============ STORY / PROCESS ============ */}
      <section className="story" id="process">
        <div className="story-image"><img src={IMG.chakki} alt="Traditional stone chakki mill grinding wheat" loading="lazy" /><span className="story-image-tag"><Wheat size={14} /> Solapur · Maharashtra</span></div>
        <div className="story-copy reveal">
          <Eyebrow>Our process · 01</Eyebrow>
          <h2 className="display">Slow stones.<br /><em>Living flour.</em></h2>
          <p>Factory roller mills run hot — 85°C and above — scorching the germ that holds all the goodness. Our emery chakkis turn slowly, keeping the grain below 28°C from first crush to final pack.</p>
          <div className="story-list">
            <div><span>01</span><div><strong>Triple-washed heritage grain</strong><small>Sourced directly from Solapur, Sangli & Malwa farms.</small></div></div>
            <div><span>02</span><div><strong>Cold stone-milled below 28°C</strong><small>Live enzymes, vitamin E and natural oils stay intact.</small></div></div>
            <div><span>03</span><div><strong>100% bran, nothing removed</strong><small>No maida, no bleach, no preservatives. Ever.</small></div></div>
            <div><span>04</span><div><strong>Dispatched in EV vans within 24h</strong><small>Freshness you can actually taste in the roti.</small></div></div>
          </div>
          <button className="btn btn-outline" onClick={() => scrollTo('compare')}>See the full comparison <ArrowRight size={16} /></button>
        </div>
      </section>

      {/* ============ BEST SELLERS ============ */}
      <section className="section shop-section" id="shop">
        <div className="container">
          <div className="reveal"><SectionHead eyebrow="The favourites" title="Best selling products" desc="Ranked by verified household repeat orders — not by marketing." action="View all" onAction={() => goView('catalog')} /></div>
          <div className="filter-row reveal">
            <div className="filters">
              {['All', 'Khapli', 'Protein', 'Family', 'Bundle'].map((f) => (
                <button key={f} className={`filter ${filter === f ? 'filter--active' : ''}`} onClick={() => setFilter(f)}>{f === 'All' ? 'All products' : f}</button>
              ))}
            </div>
            <span className="result-count">{filtered.length} products</span>
          </div>
          <div className="product-grid">
            {filtered.map((p, i) => {
              const si = sizes[p.id] ?? 0
              const size = p.sizes[si]
              return (
                <article className="product-card reveal" key={p.id} style={{ animationDelay: `${i * 55}ms` }}>
                  <div className={`product-media tone-${p.tone}`}>
                    <span className="product-tag">{p.tag}</span>
                    <button className={`wish ${wishlist.includes(p.id) ? 'wish--on' : ''}`} onClick={() => toggleWish(p.id)} aria-label="Save for later"><Heart size={16} fill={wishlist.includes(p.id) ? 'currentColor' : 'none'} /></button>
                    <button className="product-img-btn" onClick={() => setQuickView(p)} aria-label={`Quick view ${p.name}`}>
                      <img src={p.image} alt={p.name} loading="lazy" />
                    </button>
                    <span className="quick-hint">Quick view <ArrowUpRight size={13} /></span>
                  </div>
                  <div className="product-body">
                    <span className="origin"><MapPin size={11} /> {p.origin}</span>
                    <h3>{p.name}</h3>
                    <p className="product-sub">{p.subtitle}</p>
                    <div className="rating"><Stars value={p.rating} small /><span>{p.rating.toFixed(1)} <em>({p.reviews})</em></span></div>
                    <div className="size-row">
                      {p.sizes.map((s, j) => <button key={s.label} className={si === j ? 'size size--active' : 'size'} onClick={() => setSizes((v) => ({ ...v, [p.id]: j }))}>{s.label}</button>)}
                    </div>
                    <div className="product-foot">
                      <div className="product-price"><strong>{money(size.price)}</strong><s>{money(size.mrp)}</s><span className="stock"><i /> In stock</span></div>
                      <button className="add-btn" onClick={() => addItem({ id: p.id, name: p.name, image: p.image, size: size.label, price: size.price, mrp: size.mrp })}><Plus size={16} /> Add</button>
                    </div>
                  </div>
                </article>
              )
            })}
          </div>
        </div>
      </section>

      {/* ============ DELIVERY CHECK ============ */}
      <section className="delivery-band">
        <div className="container delivery-inner">
          <div className="delivery-copy"><span className="delivery-icon"><Zap size={20} /></span><div><strong>Check express 2-hour EV delivery in your area</strong><small>Fresh stoneground atta, dispatched in climate-controlled electric vans.</small></div></div>
          <form className="pin-form" onSubmit={checkPin}>
            <div className="pin-input"><MapPin size={16} /><input value={pin} onChange={(e) => { setPin(e.target.value.replace(/\D/g, '').slice(0, 6)); setPinResult(null) }} placeholder="Enter 6-digit pincode" inputMode="numeric" aria-label="Pincode" /></div>
            <button className="btn btn-dark btn-sm" type="submit">Check <ArrowRight size={15} /></button>
          </form>
        </div>
        {pinResult && <div className={`pin-result container ${pinResult.ok ? 'ok' : 'err'}`}>{pinResult.ok ? <CheckCircle2 size={15} /> : <X size={15} />}{pinResult.msg}</div>}
      </section>

      {/* ============ BUNDLES ============ */}
      <section className="section bundles-section" id="bundles">
        <div className="container">
          <div className="reveal"><SectionHead eyebrow="Better together" title="Chakki fresh value bundles" desc="Start cleaner with ready-to-use monthly stoneground grain packages and free doorstep delivery." /></div>
          <div className="bundle-grid">
            {bundles.map((b, i) => (
              <article className="bundle-card reveal" key={b.id} style={{ animationDelay: `${i * 90}ms` }}>
                <div className="bundle-media"><img src={b.image} alt={b.name} loading="lazy" /><span className="bundle-label">{b.label}</span></div>
                <div className="bundle-body">
                  <h3>{b.name}</h3>
                  <p>{b.desc}</p>
                  <ul>{b.points.map((pt) => <li key={pt}><Check size={14} /> {pt}</li>)}</ul>
                  <div className="bundle-foot">
                    <div className="bundle-price"><strong>{money(b.price)}</strong><s>{money(b.mrp)}</s><span>Save {money(b.mrp - b.price)}</span></div>
                    <button className="btn btn-dark btn-sm" onClick={() => addItem({ id: b.id, name: b.name, image: b.image, size: 'Monthly bundle', price: b.price, mrp: b.mrp })}>Add to basket <ArrowRight size={15} /></button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* ============ SALE COUNTDOWN ============ */}
      <section className="sale">
        <div className="container sale-inner">
          <div className="sale-copy">
            <span className="limited"><Sparkles size={13} /> LIMITED TIME OFFER</span>
            <h2 className="display">Super Sale <em>up to 25% off</em></h2>
            <p>Use code <strong>CLEAR50</strong> on selected cold stoneground chakki attas. New harvest, honest price.</p>
            <button className="copy-code" onClick={copyCode}><span>CLEAR50</span><span className="copy-action">{copied ? <Check size={15} /> : <Copy size={15} />} {copied ? 'Copied' : 'Copy code'}</span></button>
          </div>
          <div className="countdown">
            {[['Days', clock.d], ['Hours', clock.h], ['Mins', clock.m], ['Secs', clock.s]].map(([label, val], i) => (
              <div className="count-box" key={label}><strong>{val}</strong><span>{label}</span>{i < 3 && <i className="count-colon">:</i>}</div>
            ))}
          </div>
          <img className="sale-wheat" src={IMG.roti} alt="" aria-hidden="true" />
        </div>
      </section>

      {/* ============ RANKED ============ */}
      <section className="section ranked-section">
        <div className="container ranked-grid">
          <div className="ranked-intro reveal">
            <Eyebrow>Popular this month</Eyebrow>
            <h2 className="display">The top <em>five</em>.</h2>
            <p>Top customer favourites, ranked by verified household repeat orders — refreshed with every harvest.</p>
            <button className="btn btn-outline" onClick={() => goView('catalog')}>Shop the list <ArrowRight size={16} /></button>
            <div className="ranked-visual"><img src={IMG.roti} alt="Fresh soft rotis" loading="lazy" /></div>
          </div>
          <div className="ranked-list reveal">
            {ranked.map((r, i) => (
              <div className="rank-row" key={r.name}>
                <span className="rank-num">#{String(i + 1).padStart(2, '0')}<small>Ranked</small></span>
                <img src={r.image} alt={r.name} loading="lazy" />
                <div className="rank-info"><strong>{r.name}</strong><span><Stars value={r.rating} small /> {r.rating.toFixed(1)} · {r.size}</span></div>
                <div className="rank-price"><strong>{money(r.price)}</strong><small>{r.size}</small></div>
                <button className="rank-add" onClick={() => addItem({ id: `rank-${i}`, name: r.name, image: r.image, size: r.size, price: r.price })} aria-label={`Add ${r.name}`}><Plus size={16} /></button>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ============ ROTI CALCULATOR ============ */}
      <section className="section calc-section" id="science">
        <div className="container">
          <div className="reveal calc-head">
            <Eyebrow>Grain science & household yield</Eyebrow>
            <h2 className="display">How many rotis does <em>your</em> family need?</h2>
            <p>Because itsclear is cold-stoneground below 28°C with 100% intact bran, it absorbs <strong>72% water</strong> — yielding 36 soft rotis per kg, versus only 28 from factory-processed flour.</p>
          </div>
          <div className="calc-grid">
            <div className="calc-controls reveal">
              <div className="calc-field">
                <div className="calc-label"><span>Family members in household</span><strong>{members} People</strong></div>
                <div className="chip-row">{[2, 4, 6, 8].map((m) => <button key={m} className={`chip ${members === m ? 'chip--active' : ''}`} onClick={() => setMembers(m)}>{m} {m === 8 ? '+ ' : ''}Members</button>)}</div>
              </div>
              <div className="calc-field">
                <div className="calc-label"><span>Total rotis prepared per day</span><strong>{rotis} Rotis / Day</strong></div>
                <input className="range" type="range" min="4" max="60" value={rotis} onChange={(e) => setRotis(Number(e.target.value))} style={{ '--fill': `${((rotis - 4) / 56) * 100}%` }} />
                <div className="chip-row">{[['Light', 4], ['Average', 16], ['Large family', 40]].map(([l, v]) => <button key={l} className={`chip ${rotis === v ? 'chip--active' : ''}`} onClick={() => setRotis(v)}>{l} ({v} Rotis)</button>)}</div>
              </div>
              <div className="calc-facts">
                <div><span><Droplets size={17} /></span><div><strong>72% Water Absorption</strong><small>Retains moisture for 14h</small></div></div>
                <div><span><Wheat size={17} /></span><div><strong>36 Rotis / 1kg</strong><small>+8 rotis vs factory atta</small></div></div>
                <div><span><ShieldCheck size={17} /></span><div><strong>Zero Acid Bloat</strong><small>Water-soluble soft gluten</small></div></div>
              </div>
            </div>
            <div className="calc-result reveal">
              <div className="calc-result-top"><span className="tiny-label">MONTHLY FAMILY PROJECTION</span><strong>{monthlyRotis} <small>Rotis / Month</small></strong></div>
              <div className="bars">
                <div className="bar-row"><span>itsclear Stoneground</span><div className="bar-track"><i style={{ width: `${(Number(clearKg) / Math.max(Number(factoryKg), 1)) * 100}%`, background: 'var(--green)' }} /></div><b>{clearKg} kg/mo</b></div>
                <div className="bar-row"><span>Factory maida-atta</span><div className="bar-track"><i style={{ width: '100%', background: '#cfc6b4' }} /></div><b>{factoryKg} kg</b></div>
              </div>
              <div className="save-banner"><Sparkles size={17} /><span>You save <strong>{savedKg} kg</strong> of flour every month thanks to higher water absorption.</span></div>
              <div className="recommend">
                <span className="tiny-label">RECOMMENDED PACK FOR YOUR HOUSEHOLD</span>
                <div className="recommend-row"><img src={IMG.handle} alt="Khapli family sack with carry handle" /><div><strong>{recommended.label}</strong><small>Khapli · Cold stoneground · <b>Perfect Fit</b></small><span className="rec-price">{money(recommended.price)}</span></div></div>
                <button className="btn btn-dark btn-full" onClick={() => addItem({ id: 'calc-reco', name: 'Khapli Atta', image: IMG.family, size: recommended.label, price: recommended.price })}>Add {recommended.label} ({money(recommended.price)}) <ArrowRight size={16} /></button>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ============ COMPARISON ============ */}
      <section className="compare" id="compare">
        <div className="container">
          <div className="reveal compare-head">
            <Eyebrow light>The crystal clear truth</Eyebrow>
            <h2 className="display">Factory flour <em>vs.</em> itsclear™</h2>
            <p>Why thousands of discerning households switched from commercial roller-mill flours to authentic slow-ground whole grain atta.</p>
          </div>
          <p className="compare-swipe">Swipe sideways to see the full comparison <ArrowRight size={14} /></p>
          <div className="compare-table reveal">
            <div className="compare-th"><span>Health & milling parameter</span><span>Factory roller flour <small>Supermarket</small></span><span className="good-head"><Wheat size={16} /> itsclear™ pure stoneground</span></div>
            {comparison.map((row) => (
              <div className="compare-tr" key={row.param}>
                <div className="compare-param"><strong>{row.param}</strong><small>{row.sub}</small></div>
                <div className="compare-bad"><X size={15} /><div><strong>{row.bad}</strong><small>{row.badSub}</small></div></div>
                <div className="compare-good"><Check size={15} /><div><strong>{row.good}</strong><small>{row.goodSub}</small></div></div>
              </div>
            ))}
          </div>
          <div className="compare-cta reveal"><strong>Ready to experience 100% honest cold stoneground flour?</strong><span>Dispatched in climate-controlled electric vans within 24 hours of stone milling.</span><button className="btn btn-gold" onClick={() => goView('catalog')}>Explore all attas <ArrowRight size={16} /></button></div>
        </div>
      </section>

      {/* ============ ZERO-MAIDA LAB ============ */}
      <LabSection onToast={showToast} onCatalog={() => goView('catalog')} />

      {/* ============ CERTIFICATIONS MARQUEE ============ */}
      <section className="certs">
        <div className="cert-track">
          {[0, 1].map((k) => <div className="cert-group" key={k} aria-hidden={k === 1}>{certifications.map((c) => <span key={c}><BadgeCheck size={16} /> {c}</span>)}</div>)}
        </div>
      </section>

      {/* ============ TESTIMONIALS + STATS ============ */}
      <section className="section reviews-section" id="reviews">
        <div className="container">
          <div className="reveal"><SectionHead eyebrow="Words from real kitchens" title="What our customers say" desc="Verified buyers, unedited reviews, no filters." /></div>
          <div className="reviews-grid">
            <div className="review-card reveal">
              <Quote size={34} className="quote-mark" />
              <Stars value={5} />
              <blockquote>“{testimonials[tIndex].quote}”</blockquote>
              <div className="review-person"><span className="review-avatar">{testimonials[tIndex].initials}</span><div><strong>{testimonials[tIndex].name}</strong><small><BadgeCheck size={12} /> Verified Buyer · {testimonials[tIndex].place}</small></div></div>
              <div className="review-nav"><div className="dots">{testimonials.map((_, i) => <button key={i} className={i === tIndex ? 'dot dot--active' : 'dot'} onClick={() => setTIndex(i)} aria-label={`Review ${i + 1}`} />)}</div><div className="arrows"><button onClick={() => setTIndex((i) => (i - 1 + testimonials.length) % testimonials.length)} aria-label="Previous"><ChevronLeft size={17} /></button><button onClick={() => setTIndex((i) => (i + 1) % testimonials.length)} aria-label="Next"><ChevronRight size={17} /></button></div></div>
            </div>
            <div className="stats-card reveal">
              <span className="tiny-label">WHY SHOP WITH US</span>
              <div className="stats-grid">
                {[['10K+', 'Happy Families'], ['100%', 'Pure Cold Milled'], ['24h', 'Fresh Delivery'], ['0%', 'Added Maida']].map(([n, l]) => <div key={l}><strong>{n}</strong><span>{l}</span></div>)}
              </div>
              <div className="stats-image"><img src={IMG.roti} alt="Soft fresh rotis" loading="lazy" /><span><Sprout size={15} /> From farm to roti, nothing hidden.</span></div>
            </div>
          </div>
        </div>
      </section>

      {/* ============ FAQ ============ */}
      <section className="section faq-section" id="faq">
        <div className="container faq-grid">
          <div className="faq-intro reveal">
            <Eyebrow>Got questions?</Eyebrow>
            <h2 className="display">Frequently <em>asked</em> questions</h2>
            <p>Everything you need to know about our cold-stoneground milling, purity benchmarks and doorstep delivery.</p>
            <div className="faq-help"><span><Mail size={17} /></span><div><small>Still curious?</small><strong>hello@itsclear.in</strong></div></div>
          </div>
          <div className="faq-list reveal">
            {faqs.map((f, i) => (
              <div className={`faq-item ${faqOpen === i ? 'faq-item--open' : ''}`} key={f.q}>
                <button onClick={() => setFaqOpen(faqOpen === i ? -1 : i)}><span>{String(i + 1).padStart(2, '0')}</span>{f.q}<Plus size={17} className="faq-plus" /></button>
                <div className="faq-answer"><p>{f.a}</p></div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ============ NEWSLETTER ============ */}
      <section className="newsletter" id="subscribe">
        <div className="container newsletter-inner">
          <div className="newsletter-copy reveal">
            <Eyebrow light>Subscribe to our newsletter</Eyebrow>
            <h2 className="display">Good grain, <em>good news.</em></h2>
            <p>Get the latest updates on stoneground milling batches, harvest notes and exclusive subscriber deals.</p>
          </div>
          <form className="newsletter-form reveal" onSubmit={subscribe}>
            {subbed ? (
              <div className="subbed"><CheckCircle2 size={22} /><div><strong>You’re on the list!</strong><small>Watch your inbox for the next harvest drop.</small></div></div>
            ) : (
              <><div className="email-input"><Mail size={17} /><input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="Your email address" type="email" aria-label="Email address" /></div><button className="btn btn-gold" type="submit">Subscribe <Send size={15} /></button></>
            )}
            <label className="agree"><input type="checkbox" defaultChecked /> I agree to receive harvest purity updates and grain coupons.</label>
          </form>
        </div>
      </section>

      </>
      )}

      {/* ============ FULL CATALOG + PRODUCT DETAIL VIEWS ============ */}
      {view === 'catalog' && (
        <CatalogView
          products={products} bundles={bundles} onHome={() => goView('home')}
          onOpenProduct={(p) => goView('product', p)}
          onAdd={addItem} onToast={showToast} onSection={scrollTo}
        />
      )}
      {view === 'product' && activeProduct && (
        <ProductView
          key={activeProduct.id}
          product={activeProduct} products={products} onHome={() => goView('home')}
          onCatalog={() => goView('catalog')}
          onOpenProduct={(p) => goView('product', p)}
          onAdd={addItem} onWish={() => toggleWish(activeProduct.id)}
          wished={wishlist.includes(activeProduct.id)}
        />
      )}
      {view === 'checkout' && (
        <CheckoutView
          cart={cart} subtotal={subtotal} shipping={shipping} discount={0}
          total={checkoutTotal} onPlace={placeOrder} onBack={() => goView('home')}
        />
      )}

      {/* ============ FOOTER ============ */}
      <footer className="footer">
        <div className="container footer-top">
          <div className="footer-brand">
            <a className="brand brand--light" href="#top" onClick={(e) => { e.preventDefault(); goView('home') }}><span className="brand-mark"><Wheat size={19} /></span><span className="brand-word">itsclear<span className="brand-tm">™</span></span></a>
            <p>100% honest cold-stoneground chakki atta. Farm-direct, lab-tested, delivered fresh in electric vans.</p>
            <div className="socials">{[Instagram, Facebook, Mail].map((I, i) => <button key={i} aria-label="Social link"><I size={17} /></button>)}</div>
          </div>
          <div className="footer-col"><strong>Shop</strong>{['Khapli Atta', 'High Protein Atta', 'Family Sacks', 'Value Bundles', 'All Products'].map((x) => <button key={x} onClick={() => x === 'All Products' ? goView('catalog') : scrollTo('shop')}>{x}</button>)}</div>
          <div className="footer-col"><strong>Explore</strong>{['Our Process', 'Zero-Maida Lab', 'Grain Science', 'Compare Flours', 'Reviews', 'FAQ'].map((x) => <button key={x} onClick={() => scrollTo(x === 'Our Process' ? 'process' : x === 'Zero-Maida Lab' ? 'lab' : x === 'Grain Science' ? 'science' : x === 'Compare Flours' ? 'compare' : x === 'Reviews' ? 'reviews' : 'faq')}>{x}</button>)}</div>
          <div className="footer-col footer-contact"><strong>Get in touch</strong><span><MapPin size={14} /> Solapur, Maharashtra, India</span><span><Mail size={14} /> hello@itsclear.in</span><span><Clock size={14} /> Mon–Sat · 9am – 7pm IST</span><div className="footer-badges"><span><ShieldCheck size={13} /> FSSAI</span><span><FlaskConical size={13} /> NABL Lab</span></div></div>
        </div>
        <div className="container footer-bottom"><span>© 2026 itsclear™ Foods. Made with grain, not shortcuts.</span><div><button onClick={() => showToast('Privacy policy — demo store')}>Privacy</button><button onClick={() => showToast('Terms — demo store')}>Terms</button><button onClick={() => showToast('Refunds — demo store')}>Refunds</button></div><span className="footer-made"><Wheat size={13} /> 100% Whole Grain</span></div>
      </footer>

      {/* ============ OVERLAYS ============ */}
      {anyOverlay && <div className="scrim" onClick={() => { setCartOpen(false); setSearchOpen(false); setMenuOpen(false); setQuickView(null) }} />}

      {/* Cart drawer */}
      <aside className={`drawer ${cartOpen ? 'drawer--open' : ''}`} aria-hidden={!cartOpen}>
        <div className="drawer-head"><div><span className="tiny-label">YOUR SELECTION</span><h3>{orderPlaced ? 'Order confirmed' : `Basket (${cartCount})`}</h3></div><button className="icon-btn" onClick={() => setCartOpen(false)} aria-label="Close basket"><X size={20} /></button></div>
        {orderPlaced ? (
          <div className="order-done"><span><PackageCheck size={38} /></span><h4>Thank you for choosing honest flour!</h4><p>Your order <strong>#IC{Math.floor(10000 + Math.random() * 89999)}</strong> is being packed. Freshly milled within 24h — heading to you in an EV van.</p><button className="btn btn-dark btn-full" onClick={() => { setCart([]); setOrderPlaced(false); setCartOpen(false) }}>Continue shopping <ArrowRight size={16} /></button></div>
        ) : cart.length === 0 ? (
          <div className="empty-cart"><span><ShoppingBag size={32} /></span><h4>Your basket is empty</h4><p>Good flour makes better rotis. Start with our bestsellers.</p><button className="btn btn-dark btn-full" onClick={() => { setCartOpen(false); scrollTo('shop') }}>Explore products <ArrowRight size={16} /></button></div>
        ) : (
          <>
            <div className="ship-progress"><span>{shipLeft > 0 ? `Add ${money(shipLeft)} more for free shipping` : 'You’ve unlocked free shipping!'}</span><div className="progress"><i style={{ width: `${Math.min(100, (subtotal / 499) * 100)}%` }} /></div></div>
            <div className="cart-items">
              {cart.map((l) => (
                <div className="cart-line" key={l.key}>
                  <img src={l.image} alt={l.name} />
                  <div className="cart-line-info"><strong>{l.name}</strong><small>{l.size}</small><div className="qty"><button onClick={() => setCart((c) => c.map((x) => x.key === l.key ? { ...x, qty: Math.max(0, x.qty - 1) } : x).filter((x) => x.qty > 0))} aria-label="Decrease"><Minus size={13} /></button><span>{l.qty}</span><button onClick={() => setCart((c) => c.map((x) => x.key === l.key ? { ...x, qty: x.qty + 1 } : x))} aria-label="Increase"><Plus size={13} /></button></div></div>
                  <div className="cart-line-right"><strong>{money(l.price * l.qty)}</strong><button onClick={() => setCart((c) => c.filter((x) => x.key !== l.key))} aria-label="Remove"><Trash2 size={15} /></button></div>
                </div>
              ))}
            </div>
            <div className="drawer-foot">
              <div className="totals"><div><span>Subtotal</span><strong>{money(subtotal)}</strong></div><div><span>You save</span><strong className="green-text">− {money(savings)}</strong></div><div><span>Delivery</span><strong>{shipLeft > 0 ? money(49) : 'FREE'}</strong></div><div className="grand"><span>Total</span><strong>{money(subtotal + (shipLeft > 0 ? 49 : 0))}</strong></div></div>
              <button className="btn btn-dark btn-full" onClick={() => goView('checkout')}>Proceed to checkout <ArrowRight size={16} /></button>
              <small className="secure-note"><ShieldCheck size={13} /> Secure checkout · 100% purity guaranteed</small>
            </div>
          </>
        )}
      </aside>

      {/* Search overlay */}
      <div className={`search-panel ${searchOpen ? 'search-panel--open' : ''}`}>
        <div className="container">
          <div className="search-bar"><Search size={22} /><input autoFocus={searchOpen} value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search khapli, protein, family packs…" /><button className="icon-btn" onClick={() => setSearchOpen(false)} aria-label="Close search"><X size={20} /></button></div>
          <div className="search-body"><span className="tiny-label">{query ? `${searchResults.length} RESULTS` : 'POPULAR SEARCHES'}</span>
            {searchResults.length === 0 ? <p className="no-results">No products found. Try “khapli” or “protein”.</p> : (
              <div className="search-results">{searchResults.map((p) => <button key={p.id} onClick={() => { setSearchOpen(false); setQuickView(p) }}><img src={p.image} alt="" /><div><strong>{p.name}</strong><small>{p.subtitle}</small></div><span>{money(p.sizes[0].price)}</span><ArrowUpRight size={16} /></button>)}</div>
            )}
            <div className="search-tags">{['Khapli', 'High Protein', '10 kg', 'Bundles'].map((t) => <button key={t} onClick={() => setQuery(t)}>{t}</button>)}</div>
            <button className="search-all" onClick={() => { setSearchOpen(false); goView('catalog') }}>Browse the full catalog <ArrowRight size={14} /></button>
          </div>
        </div>
      </div>

      {/* Mobile menu */}
      <aside className={`mobile-menu ${menuOpen ? 'mobile-menu--open' : ''}`}>
        <div className="drawer-head"><span className="brand brand--light"><span className="brand-mark"><Wheat size={18} /></span><span className="brand-word">itsclear<span className="brand-tm">™</span></span></span><button className="icon-btn" onClick={() => setMenuOpen(false)} aria-label="Close menu"><X size={20} /></button></div>
        <nav>{navLinks.map((n, i) => <button key={n.id} onClick={() => { setMenuOpen(false); setTimeout(() => scrollTo(n.id), 120) }}><span>{String(i + 1).padStart(2, '0')}</span>{n.label}<ArrowUpRight size={16} /></button>)}</nav>
        <button className="btn btn-gold btn-full" onClick={() => { setMenuOpen(false); scrollTo('shop') }}>Shop the harvest <ArrowRight size={16} /></button>
      </aside>

      {/* Quick view modal */}
      {quickView && (
        <div className="modal-wrap">
          <div className="quick-modal">
            <button className="quick-close icon-btn" onClick={() => setQuickView(null)} aria-label="Close"><X size={19} /></button>
            <div className={`quick-media tone-${quickView.tone}`}><img src={quickView.image} alt={quickView.name} /></div>
            <div className="quick-body">
              <span className="product-tag">{quickView.tag}</span>
              <h3 className="display">{quickView.name}</h3>
              <p className="product-sub">{quickView.subtitle}</p>
              <div className="rating"><Stars value={quickView.rating} /><span>{quickView.rating.toFixed(1)} <em>({quickView.reviews} verified reviews)</em></span></div>
              <p className="quick-desc">Triple-washed heritage grain, slow stone-milled below 28°C with 100% bran retention. Lab-tested for zero maida, zero bleach and zero preservatives. Milled within 24 hours of dispatch.</p>
              <span className="tiny-label">CHOOSE PACK SIZE</span>
              <div className="size-row quick-sizes">{(() => { const si = sizes[quickView.id] ?? 0; return quickView.sizes.map((s, j) => <button key={s.label} className={si === j ? 'size size--active' : 'size'} onClick={() => setSizes((v) => ({ ...v, [quickView.id]: j }))}>{s.label}</button>) })()}</div>
              <div className="quick-foot"><div className="product-price"><strong>{money(quickView.sizes[sizes[quickView.id] ?? 0].price)}</strong><s>{money(quickView.sizes[sizes[quickView.id] ?? 0].mrp)}</s></div><button className="btn btn-dark" onClick={() => { const si = sizes[quickView.id] ?? 0; addItem({ id: quickView.id, name: quickView.name, image: quickView.image, size: quickView.sizes[si].label, price: quickView.sizes[si].price, mrp: quickView.sizes[si].mrp }); setQuickView(null) }}>Add to basket <ArrowRight size={16} /></button></div>
              <div className="quick-perks"><span><Truck size={14} /> Free shipping over ₹499</span><span><Award size={14} /> NABL lab certified</span></div>
              <button className="quick-detail-link" onClick={() => goView('product', quickView)}>View full product details & lab report <ArrowUpRight size={14} /></button>
            </div>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && <div className="toast" key={toast.id}><span><CheckCircle2 size={18} /></span><p>{toast.msg}</p>{toast.action === 'view' && <button onClick={() => { setCartOpen(true); setToast(null) }}>View basket <ArrowRight size={14} /></button>}<button className="toast-x" onClick={() => setToast(null)} aria-label="Dismiss"><X size={15} /></button></div>}
    </div>
  )
}
