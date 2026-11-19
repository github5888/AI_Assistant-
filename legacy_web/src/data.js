/* Exact itsclear™ pouch shots, isolated from the user's reference screenshot. */
export const IMG = {
  khapli: '/images/pack-khapli.png',
  protein: '/images/pack-protein.png',
  family: '/images/pack-lineup.png',
  badges: '/images/pack-badges.png',
  duo: '/images/pack-duo.png',
  handle: '/images/pack-handle.png',
  roti: '/images/lifestyle-roti.jpg',
  chakki: '/images/story-chakki.jpg',
}

export const categories = [
  { name: 'Khapli Atta', note: 'Ancient Low-GI', image: IMG.khapli, filter: 'Khapli' },
  { name: 'High Protein', note: '36g Protein', image: IMG.protein, filter: 'Protein' },
  { name: 'Family Sacks', note: '5kg & 10kg', image: IMG.handle, filter: 'Family' },
  { name: 'Certified Pure', note: '4 Lab Badges', image: IMG.badges, filter: 'Khapli' },
  { name: 'Protein Duo', note: 'Wheat · Soya · Peanut', image: IMG.duo, filter: 'Protein' },
  { name: 'Carry Handle', note: 'Reinforced Bags', image: IMG.handle, filter: 'Family' },
]

/* The original site's 360° viewer cycles through these five packaging shots. */
export const heroSlides = [
  {
    id: 'slide-khapli', name: 'Khapli Atta', image: IMG.khapli,
    label: '100% Khapli Wheat', spec: '14.5g Protein', badge: 'Ancient Low-GI', tone: 'green',
    packs: [{ label: '1 kg Pouch', price: 95, mrp: 115 }, { label: '5 kg Carry Handle', price: 440, mrp: 520 }, { label: '10 kg Family Sack', price: 849, mrp: 999 }],
  },
  {
    id: 'slide-protein', name: 'Premium High Protein Atta', image: IMG.protein,
    label: '36% Protein Blend', spec: '36.0g Protein', badge: 'Fitness Favourite', tone: 'clay',
    packs: [{ label: '1 kg Pouch', price: 115, mrp: 140 }, { label: '5 kg Carry Handle', price: 495, mrp: 599 }, { label: '10 kg Family Sack', price: 949, mrp: 1120 }],
  },
  {
    id: 'slide-lineup', name: 'Khapli 4-Pack Lineup', image: IMG.family,
    label: '1kg – 10kg Sizes', spec: '14.5g Protein', badge: 'Complete Range', tone: 'sand',
    packs: [{ label: '1 kg Pouch', price: 95, mrp: 115 }, { label: '5 kg Carry Handle', price: 440, mrp: 520 }, { label: '10 kg Family Sack', price: 849, mrp: 999 }],
  },
  {
    id: 'slide-badges', name: '4 Health Badges Edition', image: IMG.badges,
    label: '4 Badges Certified', spec: '14.5g Protein', badge: 'Lab Certified', tone: 'sage',
    packs: [{ label: '1 kg Pouch', price: 99, mrp: 120 }, { label: '5 kg Carry Handle', price: 440, mrp: 520 }, { label: '10 kg Family Sack', price: 849, mrp: 999 }],
  },
  {
    id: 'slide-duo', name: 'Protein Duo (5kg & 10kg)', image: IMG.duo,
    label: '36g Protein Duo', spec: '36.0g Protein', badge: 'Save 17%', tone: 'clay',
    packs: [{ label: '5 kg Carry Handle', price: 495, mrp: 599 }, { label: '10 kg Family Sack', price: 960, mrp: 1150 }],
  },
]

/* Zero-Maida Lab: batch certificate + nutrition facts used on the lab section and product detail view. */
export const labTests = [
  { test: 'Added Maida / Refined Starch', result: 'Not Detected', method: 'NABL · FTIR Spectroscopy', pass: true },
  { test: 'Benzoyl Peroxide (Bleach)', result: '0.00 ppm', method: 'NABL · HPLC', pass: true },
  { test: 'Chalk / Added Fillers', result: 'Not Detected', method: 'NABL · Gravimetric', pass: true },
  { test: 'Potassium Bromate', result: 'Not Detected', method: 'NABL · IC', pass: true },
  { test: 'Bran Retention', result: '100%', method: 'In-house sieve analysis', pass: true },
  { test: 'Peak Milling Temperature', result: '27.4°C', method: 'Continuous probe log', pass: true },
]

export const nutrition = [
  { label: 'Energy', value: '341 kcal' },
  { label: 'Protein', value: '14.5 g' },
  { label: 'Dietary Fibre', value: '12.1 g' },
  { label: 'Carbohydrate', value: '69.4 g' },
  { label: 'Fat (natural germ oils)', value: '2.1 g' },
  { label: 'Glycemic Index', value: '42 · Low' },
  { label: 'Water Absorption', value: '72 – 75%' },
  { label: 'Added Maida / Bleach', value: 'Nil' },
]

export const benchmarks = [
  { title: 'FSSAI 100% Whole Grain', code: 'LIC. 11522998000123', note: 'Whole grain compliance' },
  { title: 'Cold Chakki < 28°C', code: 'LOG 27.4°C PEAK', note: 'Live enzymes intact' },
  { title: 'NABL Lab Tested Batch', code: 'BATCH #IC-0426', note: 'Certificate with every pack' },
  { title: 'Non-GMO Ancient Heritage', code: 'EMMER · KHAPLI', note: 'Heritage seed traceability' },
  { title: 'Zero Maida & Bleach', code: '0.00 ppm NIL', note: 'Nothing added, nothing removed' },
]

export const products = [
  {
    id: 'khapli',
    name: 'Khapli Ancient Atta',
    subtitle: '100% Emmer Wheat · Low GI 42',
    origin: 'Solapur & Sangli',
    rating: 5.0,
    reviews: 342,
    image: IMG.khapli,
    tag: 'Bestseller',
    tone: 'green',
    groups: ['All', 'Khapli'],
    sizes: [
      { label: '1 kg', price: 95, mrp: 115 },
      { label: '2 kg', price: 185, mrp: 225 },
      { label: '5 kg', price: 440, mrp: 520 },
      { label: '10 kg', price: 849, mrp: 999 },
    ],
  },
  {
    id: 'protein',
    name: 'High Protein Atta',
    subtitle: '36g Protein · Wheat + Soya + Peanut',
    origin: 'Malwa & Indore',
    rating: 4.9,
    reviews: 388,
    image: IMG.protein,
    tag: 'Fitness Pick',
    tone: 'clay',
    groups: ['All', 'Protein'],
    sizes: [
      { label: '1 kg', price: 115, mrp: 140 },
      { label: '2 kg', price: 220, mrp: 270 },
      { label: '5 kg', price: 495, mrp: 599 },
      { label: '10 kg', price: 949, mrp: 1120 },
    ],
  },
  {
    id: 'lineup',
    name: 'Khapli Complete Lineup',
    subtitle: '1kg · 2kg · 5kg · 10kg Range',
    origin: 'Solapur & Sangli',
    rating: 5.0,
    reviews: 274,
    image: IMG.family,
    tag: '4 Pack Sizes',
    tone: 'sand',
    groups: ['All', 'Khapli', 'Family'],
    sizes: [
      { label: '1 kg', price: 95, mrp: 115 },
      { label: '5 kg', price: 440, mrp: 520 },
      { label: '10 kg', price: 849, mrp: 999 },
    ],
  },
  {
    id: 'badges',
    name: '4 Health Badges Edition',
    subtitle: 'High Protein · Nutrition · Natural',
    origin: 'Solapur & Sangli',
    rating: 4.9,
    reviews: 198,
    image: IMG.badges,
    tag: 'Lab Certified',
    tone: 'sage',
    groups: ['All', 'Khapli'],
    sizes: [
      { label: '1 kg', price: 99, mrp: 120 },
      { label: '5 kg', price: 440, mrp: 520 },
      { label: '10 kg', price: 849, mrp: 999 },
    ],
  },
  {
    id: 'duo',
    name: 'Protein Duo Pack',
    subtitle: '2 × 5kg High Protein Blend',
    origin: 'Malwa & Indore',
    rating: 5.0,
    reviews: 312,
    image: IMG.duo,
    tag: 'Save 17%',
    tone: 'clay',
    groups: ['All', 'Protein', 'Bundle'],
    sizes: [
      { label: '5 kg', price: 495, mrp: 599 },
      { label: '10 kg', price: 960, mrp: 1150 },
    ],
  },
]

export const bundles = [
  {
    id: 'family-kit',
    label: 'Best Value',
    name: 'Family Health Starter Kit',
    desc: 'Complete monthly stoneground nutrition for a family of four.',
    points: ['10kg Khapli Ancient Atta (Low-GI 42)', '5kg High Protein Blend (36g Protein)', 'Cold-stone ground below 28°C', 'Free express EV van delivery'],
    price: 1249,
    mrp: 1499,
    image: IMG.family,
  },
  {
    id: 'fitness-duo',
    label: 'Fitness Favourite',
    name: 'High Protein & Fitness Duo',
    desc: 'Engineered for active athletes and post-workout recovery.',
    points: ['2 × 5kg High Protein Atta', '60% Wheat · 30% Soya · 10% Peanut', 'Guaranteed zero maida & bleach', '14-hour soft rotis, all-day energy'],
    price: 960,
    mrp: 1150,
    image: IMG.duo,
  },
  {
    id: 'diabetic-care',
    label: 'Doctor Recommended',
    name: 'Diabetic & Ancient Grain Care',
    desc: 'Low-GI grain rotation recommended by clinical nutritionists.',
    points: ['5kg Khapli Emmer Stoneground Atta', '4 certified health badges on pack', 'Batch purity lab certificate included', 'Gentle soluble fibre, zero bloating'],
    price: 880,
    mrp: 1040,
    image: IMG.badges,
  },
]

export const ranked = [
  { name: 'Khapli Ancient Atta', rating: 5.0, price: 95, size: '1 kg', image: IMG.khapli },
  { name: 'High Protein Atta', rating: 4.9, price: 115, size: '1 kg', image: IMG.protein },
  { name: 'Khapli 10kg Family Pack', rating: 4.9, price: 849, size: '10 kg', image: IMG.handle },
  { name: '4 Health Badges Edition', rating: 4.9, price: 440, size: '5 kg', image: IMG.badges },
  { name: 'Protein Duo (5kg + 10kg)', rating: 5.0, price: 495, size: '5 kg', image: IMG.duo },
]

export const comparison = [
  { param: 'Milling Temperature', sub: 'Impact on vitamins & live enzymes', bad: '85°C – 95°C high heat', badSub: 'Burns wheat germ & enzymes', good: 'Below 28°C cold chakki', goodSub: 'Live enzymes & germ intact' },
  { param: 'Zero-Maida Guarantee', sub: 'Added starch or refined fillers', bad: '15% – 25% added maida', badSub: 'Gut heaviness & sugar spikes', good: '100% zero added maida', goodSub: 'Lab-tested negative for fillers' },
  { param: 'Bleach & Preservatives', sub: 'Benzoyl peroxide / bromate', bad: 'Commonly bleached', badSub: 'Artificial white appearance', good: '0.00 ppm · zero bleach', goodSub: '100% natural golden tone' },
  { param: 'Water Absorption', sub: 'Roti yield per 1kg flour', bad: '58% – 60% hydration', badSub: 'Only ~28 rotis per kg', good: '72% – 75% hydration', goodSub: '36 soft rotis per kg' },
  { param: 'Roti Freshness Life', sub: 'Softness in lunchboxes', bad: 'Hardens in 2–3 hours', badSub: 'Dry and chewy by afternoon', good: '14-hour soft roti', goodSub: 'Natural germ moisture retained' },
  { param: 'Glycemic Index', sub: 'Post-meal sugar & bloating', bad: 'High GI 74+', badSub: 'Lethargy & bloating', good: 'Clinically low GI 42', goodSub: 'Water-soluble gluten, no acidity' },
]

export const faqs = [
  { q: 'Why is cold-chakki stoneground flour superior to factory atta?', a: 'Commercial roller mills grind wheat at 80–90°C, scorching live enzymes and stripping dietary bran. Our emery stone chakkis rotate slowly below 28°C, preserving live germ, natural oils, vitamin E, coarse fibre and the grain’s natural sweetness — with no chemical additives.' },
  { q: 'How do you guarantee 100% zero maida and zero bleaching?', a: 'Every batch is NABL lab-tested for added starch, chalk and bleaching agents. The certificate travels with your pack, and our 100% bran retention makes refining physically impossible in our process.' },
  { q: 'What is Khapli (Emmer) atta and why is it recommended for diabetic care?', a: 'Khapli is an ancient heritage wheat with a clinically low glycemic index of 42 and gentle water-soluble gluten. It digests slowly, avoiding sharp post-meal glucose spikes — which is why nutritionists often recommend it for diabetic households.' },
  { q: 'How does express 2-hour EV delivery work?', a: 'Flour is stone-milled within 24 hours of dispatch and packed in climate-controlled electric vans. Enter your pincode above to check availability; eligible orders arrive at your door within two hours.' },
  { q: 'What is the shelf life of fresh stoneground atta?', a: 'Because natural germ oils are intact, we recommend consuming within 45 days of milling for peak flavour and nutrition. Store airtight in a cool, dry place — no preservatives, ever.' },
]

export const testimonials = [
  { name: 'Rajesh Sharma', place: 'Noida, Sector 62', initials: 'RS', quote: 'Amazing quality and fast delivery! The Khapli Atta is extraordinary. My father is diabetic, and his post-meal glucose spikes disappeared. The rotis stay soft all day — highly recommended.' },
  { name: 'Meera Iyer', place: 'Bengaluru, Indiranagar', initials: 'MI', quote: 'I switched from supermarket atta three months ago and the difference is unreal. No bloating, the dough absorbs so much more water, and my tiffin rotis are still soft at 4 pm.' },
  { name: 'Dr. Anil Kulkarni', place: 'Pune, Kothrud', initials: 'AK', quote: 'As a nutritionist I look at milling temperature and lab reports, not marketing. The batch certificate, 100% bran retention and low GI make this the cleanest atta I have found.' },
]

export const certifications = ['FSSAI 100% Whole Grain', 'Cold Chakki < 28°C', 'NABL Lab Tested Batch', 'Non-GMO Ancient Heritage', 'Zero Maida & Bleach', '100% Bran Retention']
