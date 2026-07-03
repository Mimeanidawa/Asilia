export interface Herb {
  id: string;
  name: string;
  scientificName: string;
  localName?: string;
  imageUrl: string;
  usedFor: string[];
  description: string;
  benefits: string[];
  howToUse: string;
  isPopular: boolean;
  category: "Herbs" | "Conditions" | "Wellness" | "Treatment";
}

export interface Condition {
  id: string;
  name: string;
  shortDesc: string;
  longDesc: string;
  remedies: string[]; // List of Herb IDs or text remedies
  iconType: "cough" | "stomach" | "heart" | "diabetes" | "skin";
}

export interface Article {
  id: string;
  title: string;
  category: "Health Tips" | "Herbs 101" | "Nutrition";
  imageUrl: string;
  readTime: string;
  summary: string;
  content: string;
}

export const HERBS: Herb[] = [
  {
    id: "neem",
    name: "Mwendo (Neem) Leaf",
    scientificName: "Azadirachta indica",
    localName: "Mwarobaini",
    imageUrl: "https://images.unsplash.com/photo-1564594736624-def7a10ab047?auto=format&fit=crop&q=80&w=400",
    usedFor: ["Immunity", "Skin", "Blood Purifier", "Fever", "Detoxification"],
    description: "Neem leaves help boost the immune system, purify the blood, treat skin conditions and fight infections. Known widely in East Africa as Mwarobaini (the tree of 40 cures), it is revered for its potent multi-healing capabilities.",
    benefits: ["Boosts Immunity", "Purifies Blood", "Treats Skin Problems", "Detoxifies Body"],
    howToUse: "Boil a handful of leaves in water for 10 minutes. Drink one cup daily. WARNING: Quite bitter but incredibly effective.",
    isPopular: true,
    category: "Herbs"
  },
  {
    id: "aloe",
    name: "Aloe Vera",
    scientificName: "Aloe barbadensis miller",
    localName: "Mshubiri",
    imageUrl: "https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=400",
    usedFor: ["Digestion", "Skin Healing", "Hydration", "Inflammation"],
    description: "Aloe Vera contains rich gel with enzymes, antioxidants, and vitamins. It is miraculous for treating tissue inflammation, stomach lining issues, and dry, cracked or sun-damaged skin.",
    benefits: ["Soothes Skin Burns", "Aids Stomach Ulcers", "Hydrates Body from Inside", "Supports Digestive Harmony"],
    howToUse: "Extract fresh cold gel from native leaves. Apply to skin directly, or blend 2 tablespoons in water/juice for tummy health.",
    isPopular: true,
    category: "Herbs"
  },
  {
    id: "ginger",
    name: "Ginger Root",
    scientificName: "Zingiber officinale",
    localName: "Tangawizi",
    imageUrl: "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=400",
    usedFor: ["Nausea", "Joint Pain", "Digestion", "Cough & Flu"],
    description: "Ginger is a spicy warm rhizome packed with gingerols. It acts as a powerful heating agent that stimulates digestive bile, breaks up nasal chest congestion, and relieves severe nausea and joints swellings.",
    benefits: ["Relieves Morning Sickness", "Combats Sore Throat & Congestion", "Reduces Arthritis Soreness", "Boosts Metabolic Fire"],
    howToUse: "Grate fresh raw root into a cup of boiling water, let steep 5 minutes. Stir in wild honey and a squeeze of fresh lemon juice. Drink hot.",
    isPopular: true,
    category: "Herbs"
  },
  {
    id: "garlic",
    name: "Garlic",
    scientificName: "Allium sativum",
    localName: "Vitunguu Saumu",
    imageUrl: "https://images.unsplash.com/photo-1540148426945-6cf215d2d9e8?auto=format&fit=crop&q=80&w=400",
    usedFor: ["Hypertension", "Heart Health", "Fungal Defense", "Immunity"],
    description: "Garlic is natures antibiotic. It contains Allicin, which dilates blood vessels to assist healthy blood flow, regulates high blood pressure, and offers active systemic defense against microbes.",
    benefits: ["Supports Stable Blood Pressure", "Slashes Bad Cholesterol", "Provides Anti-Fungal Strength", "Shortens Winter Colds"],
    howToUse: "Crush 1-2 raw garlic cloves to activate allicin, let sit for 5 minutes, then swallow with honey or mix with warm water.",
    isPopular: false,
    category: "Herbs"
  },
  {
    id: "lemongrass",
    name: "Lemongrass",
    scientificName: "Cymbopogon",
    localName: "Mchaichai",
    imageUrl: "https://images.unsplash.com/photo-1594911776569-8086036b1317?auto=format&fit=crop&q=80&w=400",
    usedFor: ["Anxiety", "Stomach Bloating", "Deep Sleep", "Fever"],
    description: "Mchaichai is a beautifully aromatic grass. In East African tradition, it is used to induce sweating to break down persistent mild fevers, and it exerts a profound tranquilizing effect on the central nervous system.",
    benefits: ["Eases Racing Thoughts", "Relieves Trapped Stomached Gas", "Induces Highly Restful Sleep", "Instantly Decongests Airways"],
    howToUse: "Simmer dry or fresh grass bundles in boiling water for 5 minutes. Best taken hot before bedtime without sugar.",
    isPopular: true,
    category: "Herbs"
  },
  {
    id: "turmeric",
    name: "Turmeric Root",
    scientificName: "Curcuma longa",
    localName: "Manjano",
    imageUrl: "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=400", // using consistent high-quality herbal image
    usedFor: ["Joint Stiffness", "Wound Cleansing", "Radiant Skin", "Cognition"],
    description: "Turmeric owes its gold hue to Curcumin, an active compound that halts biochemical pathways responsible for pain, stiffness, and arterial hardening, while bringing stellar health to hepatic functions.",
    benefits: ["Soothes Muscle & Joints Spasms", "Clears Dull Acne & Scarring", "Protects Liver Detoxification pathways", "Calms Irritated Bowels"],
    howToUse: "Stir 1 level teaspoon of pure powder into organic warm milk or coconut water, always add a tiny dash of black pepper to multiply curcumin absorption.",
    isPopular: true,
    category: "Herbs"
  }
];

export const CONDITIONS: Condition[] = [
  {
    id: "cough_flu",
    name: "Cough & Flu",
    shortDesc: "Natural remedies for cough, cold and chest congestion.",
    longDesc: "Flu and cough are viral infections of the respiratory tract. Herbal treatments focus on breakdown of mucilage, warming the lungs, and calming throat irritation with mild antiseptics.",
    remedies: ["ginger", "lemongrass", "neem"],
    iconType: "cough"
  },
  {
    id: "stomach_problems",
    name: "Stomach Problems",
    shortDesc: "Remedies for indigestion, gas, constipation, and stomach ulcers.",
    longDesc: "Digestive issues can stem from low stomach acidity, pathogen imbalance, or hyper-acidic lining inflammation. Herbs help soothe mucosa and stimulate smooth gut contraction.",
    remedies: ["aloe", "ginger", "lemongrass"],
    iconType: "stomach"
  },
  {
    id: "high_bp",
    name: "High Blood Pressure",
    shortDesc: "Herbal support for maintaining healthy blood pressure.",
    longDesc: "Chronic arterial constriction and fluid imbalance lead to hypertension. Garlic and other vasodilator herbs encourage optimal endothelial function and smooth circulation.",
    remedies: ["garlic", "neem"],
    iconType: "heart"
  },
  {
    id: "diabetes",
    name: "Diabetes",
    shortDesc: "Manage blood sugar levels naturally with tested root remedies.",
    longDesc: "Insulin resistance is majorly assisted by bitter, antioxidant leaves. Regular small doses of Neem and dietary fibers stabilize fasting blood glucose levels and nourish the pancreas.",
    remedies: ["neem", "garlic"],
    iconType: "diabetes"
  },
  {
    id: "skin_problems",
    name: "Skin Problems",
    shortDesc: "Natural solutions for acne, rashes, eczema, and skin infections.",
    longDesc: "Eczema and blemishes are usually external expressions of liver-toxin overload or bacterial skin colonies. Local topicals like Aloe combined with blood purifiers like Neem make a dual attack.",
    remedies: ["neem", "aloe", "turmeric"],
    iconType: "skin"
  }
];

export const ARTICLES: Article[] = [
  {
    id: "art-1",
    title: "Top 7 Herbs for a Strong Immune System",
    category: "Herbs 101",
    imageUrl: "https://images.unsplash.com/photo-1512290923902-8a9f81dc236c?auto=format&fit=crop&q=80&w=400",
    readTime: "4 min read",
    summary: "Boost your body's defense naturally with these time-tested herbal guardians.",
    content: "Our immune system is our shield against external invaders. While modern medicine is essential, traditional herbs like Mwarobaini (Neem), Ginger, and Garlic offer robust preventative shields. Allicin in Garlic speeds white blood cell production, gingerols in Ginger damp down cell stress, and Mwarobaini purges micro-parasites. Discover how incorporating these small remedies every morning transforms your daily energy and protects you from seasonal cold outbreaks."
  },
  {
    id: "art-2",
    title: "5 Natural Ways to Improve Digestion",
    category: "Health Tips",
    imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=400",
    readTime: "5 min read",
    summary: "Ban bloating and acid reflux with simple, daily herbal infusions.",
    content: "Healthy digestion is the root of all wellness. When bloating strikes, it signals bad stomach bile flow or sluggish bowel movement. Learn the ancient methods: 1. Drink hot ginger tea 15 minutes before a heavy meal to prime digestive acids. 2. Use Mshubiri (Aloe Vera gel) to soothe irritated colon linings. 3. Sip Lemongrass tea after dinner to dissolve trapped gases. 4. Chewing fennel or rosemary seeds as post-meal digestifs. 5. Integrate dynamic mindful deep-breathing rhythms during meals."
  },
  {
    id: "art-3",
    title: "Ancient Herbology: Decoding Mwarobaini",
    category: "Herbs 101",
    imageUrl: "https://images.unsplash.com/photo-1563170351-be82bc888bb4?auto=format&fit=crop&q=80&w=400",
    readTime: "6 min read",
    summary: "Why is the Neem tree referred to as 'arobaini' (40 cures) in traditional culture?",
    content: "Mwarobaini (Swahili word indicating 'of the forty') is famous across the Swahili coast of East Africa. Traditional folklore claims the tree is capable of curing exactly forty distinct illnesses. Scientifically, Azadirachta indica contains extremely complex bitter limonoids, which exhibit massive antibacterial, antiviral, insecticidal, and antifungal properties. Learn why chewing a clean neem twig or drinking its boiled infusion remains a standard daily hygienic ritual across many villages."
  }
];
