import { useState } from 'react'
import {
  ArrowLeft, ArrowRight, Check, CreditCard, MapPin, Package,
  ShieldCheck, Sparkles, Truck, Wallet,
} from 'lucide-react'

const money = (n) => `₹${Number(n).toLocaleString('en-IN')}`

export default function CheckoutView({ cart, subtotal, shipping, discount, total, onPlace, onBack }) {
  const [address, setAddress] = useState({
    name: 'Aarav Sharma', phone: '+91 98765 43210',
    line: '12, Green Park', city: 'Lucknow, Uttar Pradesh', pin: '226001',
  })
  const [slot, setSlot] = useState('2-hour EV')
  const [payment, setPayment] = useState('UPI')

  return (
    <div className="view-page checkout-view">
      <div className="page-hero checkout-hero">
        <div className="container">
          <div className="breadcrumb"><button onClick={onBack}><ArrowLeft size={14} /> Back to shop</button><span>/</span><strong>Checkout</strong></div>
          <h1 className="display">Almost <em>there.</em></h1>
          <p>Review your delivery details and place your order. This is a UI demo — no payment is processed.</p>
        </div>
      </div>

      <div className="container checkout-grid">
        <div className="checkout-main">
          <div className="checkout-stepper"><span className="on">01 Basket</span><i /><span className="on">02 Checkout</span><i /><span>03 Confirm</span></div>

          <section className="checkout-card">
            <div className="checkout-card-head"><MapPin size={19} /><h2>Delivery address</h2><button onClick={() => alert('Address saved — UI demo')}>Edit</button></div>
            <div className="checkout-fields">
              <label><span>Full name</span><input value={address.name} onChange={(e) => setAddress({ ...address, name: e.target.value })} /></label>
              <label><span>Phone</span><input value={address.phone} onChange={(e) => setAddress({ ...address, phone: e.target.value })} /></label>
              <label><span>Flat / house no.</span><input value={address.line} onChange={(e) => setAddress({ ...address, line: e.target.value })} /></label>
              <label><span>Pincode</span><input value={address.pin} onChange={(e) => setAddress({ ...address, pin: e.target.value })} /></label>
              <label className="wide"><span>City & state</span><input value={address.city} onChange={(e) => setAddress({ ...address, city: e.target.value })} /></label>
            </div>
          </section>

          <section className="checkout-card">
            <div className="checkout-card-head"><Truck size={19} /><h2>Delivery slot</h2></div>
            <div className="checkout-slots">
              {[['2-hour EV', '~94 mins · free'], ['Tomorrow', '9 AM – 1 PM'], ['Scheduled', 'Choose a day']].map(([t, s]) => (
                <button key={t} className={slot === t ? 'on' : ''} onClick={() => setSlot(t)}><strong>{t}</strong><small>{s}</small></button>
              ))}
            </div>
          </section>

          <section className="checkout-card">
            <div className="checkout-card-head"><Wallet size={19} /><h2>Payment method</h2></div>
            <div className="checkout-pay">
              {[['UPI', 'GPay · PhonePe · Paytm', CreditCard], ['Card', 'Credit / debit card', CreditCard], ['Cash', 'Pay on delivery', Package]].map(([t, s, I]) => (
                <button key={t} className={payment === t ? 'on' : ''} onClick={() => setPayment(t)}>
                  <span><I size={17} /></span><div><strong>{t}</strong><small>{s}</small></div><i>{payment === t && <Check size={13} />}</i>
                </button>
              ))}
            </div>
          </section>
        </div>

        <aside className="checkout-aside">
          <div className="checkout-summary-card">
            <div className="checkout-summary-head"><Sparkles size={17} /><h2>Order summary</h2><span>{cart.length} item{cart.length === 1 ? '' : 's'}</span></div>
            <div className="checkout-items">
              {cart.map((l) => (
                <div className="checkout-item" key={l.key}>
                  <img src={l.image} alt={l.name} />
                  <div><strong>{l.name}</strong><small>{l.size} · Qty {l.qty}</small></div>
                  <b>{money(l.price * l.qty)}</b>
                </div>
              ))}
            </div>
            <div className="checkout-totals">
              <div><span>Subtotal</span><b>{money(subtotal)}</b></div>
              <div><span>Delivery</span><b>{shipping ? money(shipping) : 'FREE'}</b></div>
              <div><span>Coupon</span><b className="green-text">{discount ? `− ${money(discount)}` : '—'}</b></div>
              <div className="grand"><span>Total payable</span><b>{money(total)}</b></div>
            </div>
            <button className="btn btn-dark btn-full" onClick={onPlace}>Place order · {money(total)} <ArrowRight size={16} /></button>
            <small className="secure-note"><ShieldCheck size={13} /> Secure UI demo · 100% purity guaranteed</small>
          </div>
          <div className="checkout-promise"><ShieldCheck size={20} /><div><strong>The clear standard</strong><small>Cold milled below 28°C · zero maida · lab certificate with every pack</small></div></div>
        </aside>
      </div>
    </div>
  )
}
