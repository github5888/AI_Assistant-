import { useState } from 'react'
import {
  ArrowLeft, ArrowRight, ArrowUpRight, BadgeCheck, Check, CheckCircle2, Download,
  Droplets, FlaskConical, Heart, Leaf, MapPin, PackageCheck, ShieldCheck, Star,
  Thermometer, Truck, Wheat, Zap,
} from 'lucide-react'
import { IMG, labTests, nutrition, benchmarks, testimonials } from './data.js'

const money = (n) => `₹${Number(n).toLocaleString('en-IN')}`

function Stars({ value }) {
  return (
    <span className="stars" aria-label={`${value} out of 5`}>
      {[1, 2, 3, 4, 5].map((i) => <Star key={i} size={12} fill={i <= Math.round(value) ? 'currentColor' : 'none'} strokeWidth={1.6} />)}
    </span>
  )
}

function Eyebrow({ children, light = false }) {
  return <div className={`eyebrow ${light ? 'eyebrow--light' : ''}`}><span className="eyebrow-dot" />{children}</div>
}

/* A deterministic QR-like verification mark, drawn with CSS squares. */
function VerifyMark() {
  const cells = Array.from({ length: 121 }, (_, i) => ((i * 7 + Math.floor(i / 11) * 3) % 5 < 2) || i < 33 && i % 11 < 4)
  return (
    <div className="verify-mark" aria-hidden="true">
      {cells.map((on, i) => <i key={i} className={on ? 'on' : ''} />)}
      <span className="verify-corner verify-corner--a" /><span className="verify-corner verify-corner--b" /><span className="verify-corner verify-corner--c" />
      <b><Wheat size={16} /></b>
    </div>
  )
}

/* ============================================================
   ZERO-MAIDA LAB — the site's "quality benchmarks" + proof page
   ============================================================ */
export function LabSection({ onToast, onCatalog }) {
  return (
    <section className="section lab-section" id="lab">
      <div className="container">
        <div className="section-head reveal">
          <div>
            <Eyebrow>The zero-maida lab · Batch #IC-0426</Eyebrow>
            <h2 className="display">Proof, not <em>promises.</em></h2>
            <p className="section-desc">Every harvest batch is tested at an NABL-accredited lab. The certificate travels with your pack — because "100% pure" should be a number, not a claim.</p>
          </div>
          <button className="text-link" onClick={onCatalog}>Shop lab-tested attas <ArrowUpRight size={16} /></button>
        </div>

        <div className="lab-grid">
          <div className="lab-report reveal">
            <div className="lab-report-head">
              <span className="lab-report-icon"><FlaskConical size={20} /></span>
              <div><strong>Batch Purity Certificate</strong><small>NABL Accredited Laboratory · Report IC-0426/26</small></div>
              <span className="lab-pass"><CheckCircle2 size={14} /> PASSED</span>
            </div>
            <div className="lab-report-meta">
              <div><span>BATCH</span><strong>#IC-0426</strong></div>
              <div><span>MILLED</span><strong>17 Nov 2026</strong></div>
              <div><span>SAMPLE</span><strong>Khapli Emmer</strong></div>
              <div><span>PEAK TEMP</span><strong>27.4°C</strong></div>
            </div>
            <div className="lab-table">
              {labTests.map((t) => (
                <div className="lab-row" key={t.test}>
                  <span className="lab-check"><Check size={13} /></span>
                  <div><strong>{t.test}</strong><small>{t.method}</small></div>
                  <b>{t.result}</b>
                </div>
              ))}
            </div>
            <div className="lab-report-foot">
              <span><BadgeCheck size={15} /> 6 of 6 parameters passed · nothing added, nothing removed</span>
              <button onClick={() => onToast('Batch certificate #IC-0426 added to your downloads')}><Download size={14} /> Certificate</button>
            </div>
          </div>

          <div className="lab-side reveal">
            <div className="lab-side-head">
              <h3 className="display">Our quality <em>benchmarks</em></h3>
              <p>Five independent standards, one honest flour. Traceable from heritage seed to your kitchen within 24 hours of milling.</p>
            </div>
            <div className="benchmark-list">
              {benchmarks.map((b, i) => (
                <div className="benchmark" key={b.title}>
                  <span className="benchmark-num">{String(i + 1).padStart(2, '0')}</span>
                  <div><strong>{b.title}</strong><small>{b.note}</small></div>
                  <code>{b.code}</code>
                </div>
              ))}
            </div>
            <div className="lab-verify">
              <VerifyMark />
              <div><span className="tiny-label">VERIFY YOUR PACK</span><strong>Scan the code on your sack</strong><p>See the exact milling temperature, lab results and farm of origin for the batch you hold.</p></div>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}

/* ============================================================
   FULL CATALOG VIEW
   ============================================================ */
export function CatalogView({ products, bundles, onHome, onOpenProduct, onAdd, onSection }) {
  const [filter, setFilter] = useState('All')
  const [sort, setSort] = useState('featured')

  let list = filter === 'All' ? [...products] : products.filter((p) => p.groups.includes(filter))
  if (sort === 'low') list.sort((a, b) => a.sizes[0].price - b.sizes[0].price)
  if (sort === 'high') list.sort((a, b) => b.sizes[0].price - a.sizes[0].price)
  if (sort === 'rating') list.sort((a, b) => b.rating - a.rating || b.reviews - a.reviews)

  return (
    <main className="view-page">
      <section className="page-hero">
        <div className="container">
          <div className="breadcrumb"><button onClick={onHome}>Home</button><span>/</span><strong>All attas</strong></div>
          <Eyebrow>The full harvest · 2026</Eyebrow>
          <h1 className="display">Every grain, <em>nothing hidden.</em></h1>
          <p>Five stoneground flours, three monthly bundles and four pack sizes — all cold-milled below 28°C with 100% bran retention.</p>
          <div className="page-hero-stats">
            <span><Wheat size={15} /> 5 Flours</span><span><PackageCheck size={15} /> 3 Bundles</span>
            <span><ShieldCheck size={15} /> NABL Certified</span><span><Zap size={15} /> 2-Hour EV Delivery</span>
          </div>
        </div>
      </section>

      <section className="section catalog-section">
        <div className="container">
          <div className="catalog-toolbar">
            <div className="filters">
              {['All', 'Khapli', 'Protein', 'Family', 'Bundle'].map((f) => (
                <button key={f} className={`filter ${filter === f ? 'filter--active' : ''}`} onClick={() => setFilter(f)}>{f === 'All' ? 'All attas' : f}</button>
              ))}
            </div>
            <div className="catalog-toolbar-right">
              <span className="result-count">{list.length} of {products.length} products</span>
              <label className="sort-select">Sort
                <select value={sort} onChange={(e) => setSort(e.target.value)}>
                  <option value="featured">Featured</option>
                  <option value="low">Price: low to high</option>
                  <option value="high">Price: high to low</option>
                  <option value="rating">Top rated</option>
                </select>
              </label>
            </div>
          </div>

          <div className="catalog-grid">
            {list.map((p, i) => (
              <article className="catalog-card" key={p.id} style={{ animationDelay: `${i * 55}ms` }}>
                <button className={`catalog-media tone-${p.tone}`} onClick={() => onOpenProduct(p)}>
                  <img src={p.image} alt={p.name} loading="lazy" />
                  <span className="product-tag">{p.tag}</span>
                  <span className="catalog-view">View details <ArrowUpRight size={13} /></span>
                </button>
                <div className="catalog-body">
                  <span className="origin"><MapPin size={11} /> {p.origin}</span>
                  <button className="catalog-name" onClick={() => onOpenProduct(p)}>{p.name}</button>
                  <p className="product-sub">{p.subtitle}</p>
                  <div className="rating"><Stars value={p.rating} /><span>{p.rating.toFixed(1)} <em>({p.reviews})</em></span></div>
                  <div className="catalog-foot">
                    <div><small>FROM</small><strong>{money(p.sizes[0].price)}</strong><s>{money(p.sizes[0].mrp)}</s></div>
                    <button className="add-btn" onClick={() => onAdd({ id: p.id, name: p.name, image: p.image, size: p.sizes[0].label, price: p.sizes[0].price, mrp: p.sizes[0].mrp })}><span>+</span> Add</button>
                  </div>
                </div>
              </article>
            ))}
          </div>
          {list.length === 0 && <div className="catalog-empty">No flours in this category yet. <button onClick={() => setFilter('All')}>Show all attas</button></div>}

          <div className="catalog-bundles">
            <div className="catalog-bundles-head"><Eyebrow>Better together</Eyebrow><h2 className="display">Monthly value bundles</h2><p>Ready-to-use stoneground grain packages with free doorstep delivery.</p></div>
            <div className="catalog-bundle-grid">
              {bundles.map((b) => (
                <div className="catalog-bundle" key={b.id}>
                  <img src={b.image} alt={b.name} loading="lazy" />
                  <div><span className="bundle-label">{b.label}</span><strong>{b.name}</strong><p>{b.desc}</p><div className="bundle-price"><b>{money(b.price)}</b><s>{money(b.mrp)}</s></div></div>
                  <button className="btn btn-dark btn-sm" onClick={() => onAdd({ id: b.id, name: b.name, image: b.image, size: 'Monthly bundle', price: b.price, mrp: b.mrp })}>Add to basket <ArrowRight size={14} /></button>
                </div>
              ))}
            </div>
          </div>

          <div className="catalog-cta">
            <div><strong>Not sure how much your family needs?</strong><span>Use the roti calculator to find your perfect pack in under ten seconds.</span></div>
            <button className="btn btn-dark" onClick={() => onSection('science')}>Open the calculator <ArrowRight size={16} /></button>
          </div>
        </div>
      </section>
    </main>
  )
}

/* ============================================================
   PRODUCT DETAIL VIEW
   ============================================================ */
export function ProductView({ product, products, onHome, onCatalog, onOpenProduct, onAdd, onWish, wished }) {
  const [sizeIdx, setSizeIdx] = useState(0)
  const [qty, setQty] = useState(1)
  const [tab, setTab] = useState('overview')
  const size = product.sizes[sizeIdx]
  const gallery = [product.image, IMG.protein, IMG.family, IMG.badges, IMG.handle, IMG.duo, IMG.khapli]
    .filter((x, i, a) => a.indexOf(x) === i).slice(0, 4)
  const [photo, setPhoto] = useState(gallery[0])
  const related = products.filter((p) => p.id !== product.id).slice(0, 3)

  return (
    <main className="view-page">
      <section className="page-hero page-hero--product">
        <div className="container">
          <div className="breadcrumb"><button onClick={onHome}>Home</button><span>/</span><button onClick={onCatalog}>All attas</button><span>/</span><strong>{product.name}</strong></div>
        </div>
      </section>

      <section className="section detail-section">
        <div className="container">
          <div className="detail-top">
            <div className="detail-gallery">
              <div className={`detail-main tone-${product.tone}`}>
                <img src={photo} alt={product.name} />
                <span className="product-tag">{product.tag}</span>
                <span className="detail-temp"><Thermometer size={14} /> Milled below 28°C</span>
              </div>
              <div className="detail-thumbs">
                {gallery.map((g, i) => <button key={g + i} className={photo === g ? 'active' : ''} onClick={() => setPhoto(g)}><img src={g} alt="" /></button>)}
              </div>
            </div>

            <div className="detail-info">
              <span className="origin"><MapPin size={12} /> {product.origin}</span>
              <h1 className="display">{product.name}</h1>
              <p className="detail-sub">{product.subtitle}</p>
              <div className="rating"><Stars value={product.rating} /><span>{product.rating.toFixed(1)} <em>({product.reviews} verified reviews)</em></span></div>
              <div className="detail-price"><strong>{money(size.price)}</strong><s>{money(size.mrp)}</s><span>Save {money(size.mrp - size.price)}</span></div>
              <span className="tiny-label">CHOOSE PACK SIZE</span>
              <div className="size-row detail-sizes">
                {product.sizes.map((s, i) => <button key={s.label} className={sizeIdx === i ? 'size size--active' : 'size'} onClick={() => setSizeIdx(i)}>{s.label}</button>)}
              </div>
              <div className="detail-buy">
                <div className="qty qty--lg"><button onClick={() => setQty((q) => Math.max(1, q - 1))} aria-label="Decrease">−</button><span>{qty}</span><button onClick={() => setQty((q) => q + 1)} aria-label="Increase">+</button></div>
                <button className="btn btn-dark" onClick={() => onAdd({ id: product.id, name: product.name, image: product.image, size: size.label, price: size.price, mrp: size.mrp }, false)}>Add {qty} to basket <ArrowRight size={16} /></button>
                <button className={`detail-wish ${wished ? 'wish--on' : ''}`} onClick={onWish} aria-label="Save for later"><Heart size={18} fill={wished ? 'currentColor' : 'none'} /></button>
              </div>
              <div className="detail-perks">
                <span><Truck size={15} /> Free shipping over ₹499</span>
                <span><Zap size={15} /> 2-hour EV delivery</span>
                <span><ShieldCheck size={15} /> Batch lab certificate</span>
              </div>
              <div className="detail-facts">
                <div><Thermometer size={17} /><strong>&lt; 28°C</strong><small>Cold stone milled</small></div>
                <div><Droplets size={17} /><strong>72%</strong><small>Water absorption</small></div>
                <div><Leaf size={17} /><strong>100%</strong><small>Bran retained</small></div>
                <div><Wheat size={17} /><strong>36</strong><small>Rotis per kg</small></div>
              </div>
            </div>
          </div>

          <div className="detail-tabs">
            <div className="tab-bar">
              {[['overview', 'Overview'], ['nutrition', 'Nutrition facts'], ['lab', 'Lab report'], ['reviews', 'Reviews']].map(([k, l]) => (
                <button key={k} className={tab === k ? 'tab--active' : ''} onClick={() => setTab(k)}>{l}</button>
              ))}
            </div>
            {tab === 'overview' && (
              <div className="tab-panel tab-overview">
                <div><Eyebrow>From farm to roti</Eyebrow><h3 className="display">Slow stones. <em>Living flour.</em></h3><p>Triple-washed heritage grain sourced directly from {product.origin}, ground slowly on emery stone chakkis that never exceed 28°C. Live enzymes, natural germ oils, vitamin E and coarse fibre stay exactly where nature put them.</p><p>No maida, no bleach, no preservatives — and a batch purity certificate in every pack. Milled within 24 hours of dispatch and delivered in climate-controlled electric vans.</p></div>
                <div className="overview-cards">
                  {[[Thermometer, 'Cold Chakki', 'Peak 27.4°C · live enzymes intact'], [ShieldCheck, 'Zero Maida', 'Lab-tested negative for starch & chalk'], [Leaf, '100% Bran', 'Nothing sifted out, nothing added in'], [Zap, '24h Fresh', 'Stone-milled within a day of dispatch']].map(([I, t, s]) => (
                    <div key={t}><span><I size={18} /></span><strong>{t}</strong><small>{s}</small></div>
                  ))}
                </div>
              </div>
            )}
            {tab === 'nutrition' && (
              <div className="tab-panel tab-nutrition">
                <div><Eyebrow>Per 100g · Khapli Emmer</Eyebrow><h3 className="display">What's <em>inside</em>.</h3><p>Values from NABL-tested batch #IC-0426. Natural variation ±5% between harvests.</p><span className="nutrition-note"><BadgeCheck size={14} /> No additives, no fortification, no bleaching agents.</span></div>
                <div className="nutrition-table">{nutrition.map((n) => <div key={n.label}><span>{n.label}</span><strong>{n.value}</strong></div>)}</div>
              </div>
            )}
            {tab === 'lab' && (
              <div className="tab-panel tab-lab">
                <div><Eyebrow>Batch #IC-0426</Eyebrow><h3 className="display">The <em>clear</em> report.</h3><p>Six independent purity parameters, all passed. A physical copy of this certificate ships with every pack.</p><span className="lab-pass lab-pass--big"><CheckCircle2 size={16} /> 6 / 6 PASSED</span></div>
                <div className="lab-table lab-table--compact">{labTests.map((t) => <div className="lab-row" key={t.test}><span className="lab-check"><Check size={13} /></span><div><strong>{t.test}</strong><small>{t.method}</small></div><b>{t.result}</b></div>)}</div>
              </div>
            )}
            {tab === 'reviews' && (
              <div className="tab-panel tab-reviews">
                <div><Eyebrow>Verified buyers</Eyebrow><h3 className="display">Real <em>kitchens</em>.</h3><p>{product.reviews} verified reviews · {product.rating.toFixed(1)} average rating.</p></div>
                <div className="review-mini-grid">{testimonials.map((t) => <div className="review-mini" key={t.name}><Stars value={5} /><p>“{t.quote}”</p><div><span>{t.initials}</span><div><strong>{t.name}</strong><small>{t.place}</small></div></div></div>)}</div>
              </div>
            )}
          </div>

          <div className="related">
            <div className="related-head"><div><Eyebrow>You may also like</Eyebrow><h2 className="display">More from the <em>harvest</em>.</h2></div><button className="text-link" onClick={onCatalog}>View all attas <ArrowUpRight size={16} /></button></div>
            <div className="related-grid">
              {related.map((p) => (
                <button className="related-card" key={p.id} onClick={() => { setSizeIdx(0); onOpenProduct(p) }}>
                  <img src={p.image} alt={p.name} loading="lazy" />
                  <div><strong>{p.name}</strong><span>{p.subtitle}</span><b>{money(p.sizes[0].price)}</b></div>
                  <ArrowUpRight size={16} />
                </button>
              ))}
            </div>
          </div>

          <button className="back-link" onClick={onCatalog}><ArrowLeft size={15} /> Back to all attas</button>
        </div>
      </section>
    </main>
  )
}
