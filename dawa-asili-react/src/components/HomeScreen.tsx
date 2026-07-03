import React, { useState } from "react";
import { useApp } from "../context/AppContext";
import { HERBS, CONDITIONS } from "../data";
import { Search, Bell, Menu, ShieldAlert, Sparkles, ChevronRight, Leaf, Clock } from "lucide-react";

export default function HomeScreen() {
  const { navigate, toggleFavorite, isFavorite } = useApp();
  const [searchQuery, setSearchQuery] = useState("");

  const [recentSearches, setRecentSearches] = useState<string[]>(() => {
    try {
      const saved = localStorage.getItem("da_recent_searches");
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  const [isInputFocused, setIsInputFocused] = useState(false);

  const commitSearch = (query: string) => {
    const trimmed = query.trim();
    if (!trimmed) return;
    setRecentSearches((prev) => {
      const filtered = prev.filter((item) => item.toLowerCase() !== trimmed.toLowerCase());
      const updated = [trimmed, ...filtered].slice(0, 3);
      localStorage.setItem("da_recent_searches", JSON.stringify(updated));
      return updated;
    });
  };

  const clearRecentSearches = () => {
    setRecentSearches([]);
    localStorage.removeItem("da_recent_searches");
  };

  const handleSelectSearchResult = (screen: string, payload: any) => {
    commitSearch(searchQuery);
    navigate(screen as any, payload);
  };

  const filteredHerbs = HERBS.filter(
    (herb) =>
      herb.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      herb.scientificName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (herb.localName && herb.localName.toLowerCase().includes(searchQuery.toLowerCase())) ||
      herb.usedFor.some((use) => use.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  const filteredConditions = CONDITIONS.filter((c) =>
    c.name.toLowerCase().includes(searchQuery.toLowerCase())
  );

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] overflow-y-auto pb-20 select-none">
      {/* Top Header */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03]">
        <button className="p-1 rounded-full hover:bg-emerald-50 text-[#113121] transition-colors">
          <Menu className="w-5 h-5" />
        </button>
        <div className="flex items-center space-x-1.5 font-bold font-serif text-[#113121]">
          <Leaf className="w-4 h-4 text-emerald-700" />
          <span className="text-base tracking-tight">Dawa Asili</span>
        </div>
        <button 
          className="p-1.5 rounded-full hover:bg-emerald-50 text-[#113121] relative transition-colors"
          onClick={() => navigate("profile")}
        >
          <Bell className="w-5 h-5" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#836C45]" />
        </button>
      </div>

      {/* Greeting and Mortar Graphic */}
      <div className="px-5 pt-5 pb-5 bg-gradient-to-b from-white to-[#FAF7F2]">
        <div className="flex justify-between items-start">
          <div className="space-y-1">
            <h3 className="text-2xl font-black font-sans tracking-tight text-[#113121]">
              Karibu!
            </h3>
            <p className="text-xs text-gray-500 font-medium">
              What would you like to heal today?
            </p>
          </div>
          {/* Mortar Illustration */}
          <div className="w-16 h-16 rounded-2xl bg-emerald-50 border border-emerald-800/10 flex items-center justify-center p-2.5">
            <svg viewBox="0 0 64 64" className="w-full h-full text-[#113121] fill-current opacity-90 animate-pulse">
              <path d="M54,42v4H10v-4c0-4.4,3.6-8,8-8h28C50.4,34,54,37.6,54,42z M14,14h36c2.2,0,4,1.8,4,4c0,3.3-2.7,6-6,6H16c-3.3,0-6-2.7-6-6 C10,15.8,11.8,14,14,14z M8,52c0-1.1,0.9-2,2-2h44c1.1,0,2,0.9,2,2s-0.9,2-2,2H10C8.9,54,8,53.1,8,52z M45.8,11.3l5.5-5.5 c0.8-0.8,2-0.8,2.8,0l2.1,2.1c0.8,0.8,0.8,2,0,2.8l-5.5,5.5L45.8,11.3z" />
            </svg>
          </div>
        </div>

        {/* Search Bar */}
        <div className="mt-5 relative" id="search-bar-container">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-emerald-800/60" />
          <input
            type="text"
            placeholder="Search herbs, cures, or health issues..."
            value={searchQuery}
            onFocus={() => setIsInputFocused(true)}
            onBlur={() => {
              // Delay slightly so click events on dropdown items can fire before focus is lost
              setTimeout(() => setIsInputFocused(false), 200);
            }}
            onKeyDown={(e) => {
              if (e.key === "Enter") {
                commitSearch(searchQuery);
              }
            }}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full bg-white border border-emerald-800/10 rounded-2xl py-3 pl-10 pr-4 text-sm font-medium text-[#113121] placeholder-emerald-800/40 focus:outline-none focus:ring-2 focus:ring-[#113121]/10 focus:border-[#113121] shadow-sm transition-all"
          />

          {/* Recent Searches Dropdown */}
          {isInputFocused && recentSearches.length > 0 && (
            <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-emerald-800/10 rounded-2xl shadow-lg z-50 p-3.5 space-y-2 animate-in fade-in slide-in-from-top-2 duration-205">
              <div className="flex items-center justify-between px-1 pb-1 border-b border-emerald-800/[0.04]">
                <span className="text-[10px] uppercase tracking-wider text-gray-400 font-bold flex items-center gap-1.5">
                  <Clock className="w-3.5 h-3.5 text-[#836C45]" /> Recent Searches
                </span>
                <button
                  type="button"
                  onMouseDown={(e) => {
                    // Prevent input blur before click is handled
                    e.preventDefault();
                  }}
                  onClick={() => clearRecentSearches()}
                  className="text-[10px] text-red-500 hover:text-red-700 font-extrabold transition-colors cursor-pointer"
                >
                  Clear All
                </button>
              </div>
              <div className="space-y-1 animate-in fade-in duration-100">
                {recentSearches.map((term, index) => (
                  <button
                    key={index}
                    type="button"
                    onMouseDown={(e) => {
                      // Prevent input blur before click is handled
                      e.preventDefault();
                    }}
                    onClick={() => {
                      setSearchQuery(term);
                      setIsInputFocused(false);
                    }}
                    className="w-full text-left px-2.5 py-2 hover:bg-emerald-50/50 rounded-xl text-xs font-bold text-[#113121] flex items-center justify-between group transition-colors"
                  >
                    <span className="truncate">{term}</span>
                    <ChevronRight className="w-3.5 h-3.5 text-emerald-800/30 group-hover:text-emerald-800 transition-colors" />
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>

      {searchQuery ? (
        /* Results Mode */
        <div className="px-5 py-4 space-y-4">
          <div className="flex items-center justify-between mb-1">
            <h4 className="text-xs uppercase tracking-wider text-gray-400 font-bold">Search Results</h4>
            <span className="text-[10px] bg-emerald-50 px-2.5 py-1 rounded-full font-bold text-emerald-800">
              {filteredHerbs.length + filteredConditions.length} found
            </span>
          </div>

          {filteredHerbs.length > 0 && (
            <div className="space-y-2.5">
              <h5 className="text-xs font-bold text-emerald-800">Matching Herbs</h5>
              {filteredHerbs.map((h) => (
                <div
                  key={h.id}
                  onClick={() => handleSelectSearchResult("herb-details", { herbId: h.id })}
                  className="flex items-center space-x-3 p-2.5 rounded-xl bg-white border border-emerald-800/[0.03] shadow-sm cursor-pointer hover:bg-emerald-50/50 transition-colors"
                >
                  <img src={h.imageUrl} alt={h.name} className="w-11 h-11 rounded-lg object-cover shrink-0" />
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-bold truncate text-[#113121]">{h.name}</p>
                    <p className="text-[10px] text-gray-400 font-mono italic truncate">{h.scientificName}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-emerald-800/40 shrink-0" />
                </div>
              ))}
            </div>
          )}

          {filteredConditions.length > 0 && (
            <div className="space-y-2.5 pt-2">
              <h5 className="text-xs font-bold text-emerald-800">Matching Conditions</h5>
              {filteredConditions.map((c) => (
                <div
                  key={c.id}
                  onClick={() => handleSelectSearchResult("conditions", { conditionId: c.id })}
                  className="flex items-center justify-between p-3 rounded-xl bg-white border border-emerald-800/[0.03] shadow-sm cursor-pointer hover:bg-emerald-50/50 transition-colors"
                >
                  <div>
                    <p className="text-sm font-bold text-[#113121]">{c.name}</p>
                    <p className="text-xs text-gray-400 truncate max-w-[200px]">{c.shortDesc}</p>
                  </div>
                  <ChevronRight className="w-4 h-4 text-emerald-800/40" />
                </div>
              ))}
            </div>
          )}

          {filteredHerbs.length === 0 && filteredConditions.length === 0 && (
            <div className="py-12 text-center text-gray-400">
              <p className="text-sm font-medium">No direct cures found for &quot;{searchQuery}&quot;.</p>
              <button 
                onClick={() => navigate("ask-expert")}
                className="mt-3 text-xs font-bold text-emerald-800 underline block mx-auto"
              >
                Ask our expert specialist instead
              </button>
            </div>
          )}
        </div>
      ) : (
        /* Standard Layout Mode */
        <>
          {/* Quick Category Grid */}
          <div className="px-5 mt-2">
            <div className="grid grid-cols-4 gap-2.5">
              {[
                { name: "Herbs", icon: "🌱", active: true, action: () => {} },
                { name: "Conditions", icon: "🤒", active: false, action: () => navigate("conditions") },
                { name: "Wellness", icon: "🧘", active: false, action: () => navigate("learn") },
                { name: "Treatment", icon: "🧪", active: false, action: () => navigate("conditions") }
              ].map((cat, i) => (
                <button
                  key={i}
                  onClick={cat.action}
                  className="flex flex-col items-center justify-between p-3 rounded-2xl bg-white border border-emerald-800/[0.04] shadow-[0_2px_12px_rgba(17,49,33,0.01)] hover:scale-105 transition-all text-center"
                >
                  <div className="text-2xl mb-1.5">{cat.icon}</div>
                  <span className="text-[10px] font-extrabold text-[#113121] tracking-tight truncate w-full">
                    {cat.name}
                  </span>
                </button>
              ))}
            </div>
          </div>

          {/* Recommended for You Grid */}
          <div className="px-5 mt-6">
            <div className="flex items-center justify-between mb-3">
              <h4 className="text-sm font-black font-sans tracking-tight text-[#113121]">
                Recommended for You
              </h4>
              <button 
                onClick={() => navigate("conditions")}
                className="text-[10px] font-bold text-gray-400 hover:text-emerald-800 transition-colors"
              >
                View all
              </button>
            </div>

            {/* Horizontal recommended cards */}
            <div className="flex space-x-4 overflow-x-auto pb-2 scrollbar-none snap-x -mx-5 px-5">
              {[
                {
                  id: "neem",
                  theme: "For Better Immunity",
                  name: "Mwendo (Neem) Leaf",
                  desc: "Natural immune booster, fever breaker, and deep systemic blood cleanser.",
                  imageUrl: "https://images.unsplash.com/photo-1564594736624-def7a10ab047?auto=format&fit=crop&q=80&w=400",
                },
                {
                  id: "aloe",
                  theme: "For Soothing Digestion",
                  name: "Aloe Vera (Mshubiri)",
                  desc: "Cools hot acidity, protects tummy mucilage, and supports hydration.",
                  imageUrl: "https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=400",
                },
                {
                  id: "lemongrass",
                  theme: "For Calming Nerves",
                  name: "Lemongrass (Mchaichai)",
                  desc: "Instantly lowers anxiety, aids deep slumber, and helps congestion.",
                  imageUrl: "https://images.unsplash.com/photo-1594911776569-8086036b1317?auto=format&fit=crop&q=80&w=400",
                }
              ].map((item, id) => (
                <div
                  key={id}
                  className="min-w-[230px] w-[230px] bg-white border border-emerald-800/[0.03] rounded-2xl p-3.5 shadow-sm snap-start"
                >
                  <div className="text-[10px] font-extrabold text-[#836C45] uppercase tracking-wide">
                    {item.theme}
                  </div>
                  <h4 className="text-base font-bold text-[#113121] tracking-tight mt-0.5">{item.name}</h4>
                  <p className="text-[10px] text-gray-500 line-clamp-2 leading-relaxed mt-1">
                    {item.desc}
                  </p>
                  
                  <div className="flex items-center justify-between mt-3 pt-3 border-t border-emerald-800/[0.03]">
                    <button
                      onClick={() => navigate("herb-details", { herbId: item.id })}
                      className="bg-[#113121] hover:bg-emerald-900 text-[#FAF7F2] px-3.5 py-1.5 rounded-xl text-[10px] font-bold"
                    >
                      Learn More
                    </button>
                    <img src={item.imageUrl} alt={item.name} className="w-10 h-10 rounded-lg object-cover border border-emerald-800/10" />
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Popular Remedies Section */}
          <div className="px-5 mt-6">
            <div className="flex items-center justify-between mb-3">
              <h4 className="text-sm font-black font-sans tracking-tight text-[#113121]">
                Popular Remedies
              </h4>
              <button 
                onClick={() => navigate("conditions")}
                className="text-[10px] font-bold text-gray-400 hover:text-emerald-800"
              >
                View all
              </button>
            </div>

            <div className="grid grid-cols-3 gap-3">
              {[
                {
                  title: "Tumbo Imara",
                  sub: "(Strong Stomach)",
                  emoji: "🧉",
                  conditionId: "stomach_problems",
                  image: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?auto=format&fit=crop&q=80&w=150"
                },
                {
                  title: "Homa (Cough)",
                  sub: "Relief Essence",
                  emoji: "🍯",
                  conditionId: "cough_flu",
                  image: "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=150"
                },
                {
                  title: "Ngozi Safi",
                  sub: "(Clear Radiant Skin)",
                  emoji: "🧴",
                  conditionId: "skin_problems",
                  image: "https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=150"
                }
              ].map((item, i) => (
                <div
                  key={i}
                  onClick={() => navigate("conditions", { conditionId: item.conditionId })}
                  className="bg-white border border-emerald-800/[0.03] rounded-2xl p-2 text-center cursor-pointer hover:border-emerald-800/25 hover:shadow-sm transition-all"
                >
                  <img src={item.image} alt={item.title} className="w-full h-14 object-cover rounded-xl mb-1.5" />
                  <p className="text-[10px] font-extrabold text-[#113121] leading-none line-clamp-1">
                    {item.title}
                  </p>
                  <p className="text-[8px] text-gray-400 scale-95 leading-none mt-0.5 block">
                    {item.sub}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
