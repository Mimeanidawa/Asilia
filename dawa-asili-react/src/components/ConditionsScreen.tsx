import React, { useState } from "react";
import { useApp } from "../context/AppContext";
import { CONDITIONS, HERBS, Condition } from "../data";
import { Search, Flame, ShieldAlert, Heart, Activity, Thermometer, UserCheck, ChevronRight, Sparkles, X } from "lucide-react";

export default function ConditionsScreen() {
  const { navigate, selectedConditionId } = useApp();
  const [search, setSearch] = useState("");
  const [activeCondition, setActiveCondition] = useState<Condition | null>(() => {
    return CONDITIONS.find((c) => c.id === selectedConditionId) || null;
  });

  const filteredConditions = CONDITIONS.filter(
    (c) =>
      c.name.toLowerCase().includes(search.toLowerCase()) ||
      c.shortDesc.toLowerCase().includes(search.toLowerCase()) ||
      c.longDesc.toLowerCase().includes(search.toLowerCase())
  );

  const getConditionIcon = (type: string) => {
    switch (type) {
      case "cough":
        return <Thermometer className="w-5 h-5 text-red-600" />;
      case "stomach":
        return <Activity className="w-5 h-5 text-amber-600" />;
      case "heart":
        return <Flame className="w-5 h-5 text-rose-600" />;
      case "diabetes":
        return <ShieldAlert className="w-5 h-5 text-indigo-600" />;
      case "skin":
        return <UserCheck className="w-5 h-5 text-emerald-600" />;
      default:
        return <Activity className="w-5 h-5 text-teal-650" />;
    }
  };

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] select-none">
      {/* Top Header */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03] shrink-0">
        <div className="flex items-center space-x-2">
          <Activity className="w-4 h-4 text-emerald-800" />
          <span className="text-sm font-black font-sans uppercase tracking-tight">Conditions</span>
        </div>
      </div>

      {/* Search Conditions Input */}
      <div className="p-4 bg-white border-b border-emerald-800/[0.03] shrink-0">
        <div className="relative">
          <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-emerald-800/50" />
          <input
            type="text"
            placeholder="Search health conditions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full bg-emerald-50/10 border border-emerald-800/10 rounded-xl py-3 pl-10 pr-4 text-xs font-semibold text-[#113121] placeholder-emerald-800/45 focus:outline-none focus:ring-1 focus:ring-[#113121] focus:bg-white transition-all shadow-inner"
          />
        </div>
      </div>

      {/* Conditions Scrollable List grid */}
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-3.5 pb-20">
        <h4 className="text-xs font-black uppercase tracking-wider text-gray-400">
          Target Health Areas
        </h4>

        <div className="grid grid-cols-1 gap-3">
          {filteredConditions.map((cond) => (
            <div
              key={cond.id}
              onClick={() => setActiveCondition(cond)}
              className="flex items-center space-x-3.5 p-3.5 bg-white border border-emerald-800/[0.03] rounded-2xl shadow-sm hover:border-emerald-800/10 cursor-pointer transition-all hover:translate-x-0.5"
            >
              <div className="w-10 h-10 rounded-xl bg-emerald-50/40 border border-emerald-800/10 flex items-center justify-center shrink-0">
                {getConditionIcon(cond.iconType)}
              </div>
              <div className="min-w-0 flex-1">
                <p className="text-sm font-black text-[#113121] tracking-tight">{cond.name}</p>
                <p className="text-[10px] text-gray-500 leading-normal line-clamp-1">{cond.shortDesc}</p>
              </div>
              <ChevronRight className="w-4 h-4 text-emerald-800/30" />
            </div>
          ))}

          {filteredConditions.length === 0 && (
            <div className="py-12 text-center text-gray-400 font-medium">
              <p className="text-sm">No matched health categories found.</p>
              <button 
                onClick={() => setSearch("")}
                className="mt-2 text-xs font-bold text-emerald-800 underline block mx-auto"
              >
                Reset Filter
              </button>
            </div>
          )}
        </div>
      </div>

      {/* Bottom overlay for active condition details (Click sheet card) */}
      {activeCondition && (
        <div className="absolute inset-0 bg-black/40 z-30 flex flex-col justify-end animate-in fade-in duration-200">
          <div className="bg-[#FAF7F2] rounded-t-[32px] border-t border-emerald-800/10 p-5 space-y-5 shadow-2xl max-h-[85%] overflow-y-auto pb-16">
            {/* Header row */}
            <div className="flex justify-between items-start">
              <div className="flex items-center space-x-3">
                <div className="w-10 h-10 rounded-xl bg-emerald-100 flex items-center justify-center">
                  {getConditionIcon(activeCondition.iconType)}
                </div>
                <div>
                  <h4 className="text-base font-black font-sans text-[#113121] leading-none">
                    {activeCondition.name}
                  </h4>
                  <p className="text-[10px] text-gray-400 font-bold tracking-wide uppercase mt-1">
                    Condition Analysis
                  </p>
                </div>
              </div>
              <button
                onClick={() => setActiveCondition(null)}
                className="p-1 rounded-full bg-white border border-emerald-800/10 text-gray-400 hover:text-red-700 hover:scale-105 transition-all shadow-sm"
              >
                <X className="w-5 h-5 animate-pulse" />
              </button>
            </div>

            {/* Condition Description */}
            <div className="space-y-1">
              <h5 className="text-[10px] font-extrabold uppercase tracking-wide text-gray-400">Holistic Understanding</h5>
              <p className="text-xs text-gray-600 leading-relaxed font-sans font-semibold">
                {activeCondition.longDesc}
              </p>
            </div>

            {/* Core Botanical Remedies grid */}
            <div className="space-y-3 pt-1">
              <div className="flex items-center space-x-1.5 text-emerald-800">
                <Sparkles className="w-3.5 h-3.5 text-[#836C45]" />
                <h5 className="text-[10px] font-extrabold uppercase tracking-wide">Recommended Botanical Remedies</h5>
              </div>
              
              <div className="grid grid-cols-1 gap-2.5">
                {activeCondition.remedies.map((remedyId) => {
                  const herb = HERBS.find((h) => h.id === remedyId);
                  if (!herb) return null;
                  return (
                    <div
                      key={herb.id}
                      onClick={() => {
                        setActiveCondition(null);
                        navigate("herb-details", { herbId: herb.id });
                      }}
                      className="flex items-center space-x-3 p-2.5 rounded-xl bg-white border border-emerald-800/[0.04] shadow-sm cursor-pointer hover:border-[#113121]/30 transition-all"
                    >
                      <img src={herb.imageUrl} alt={herb.name} className="w-12 h-12 rounded-lg object-cover" />
                      <div className="flex-1 min-w-0">
                        <p className="text-xs font-extrabold text-[#113121]">{herb.name}</p>
                        <p className="text-[9px] text-gray-400 italic truncate font-mono">{herb.scientificName}</p>
                      </div>
                      <ChevronRight className="w-4 h-4 text-emerald-800/30" />
                    </div>
                  );
                })}
              </div>
            </div>

            {/* AI consultant button proxy */}
            <div className="pt-2">
              <button
                onClick={() => {
                  setActiveCondition(null);
                  navigate("ask-expert");
                }}
                className="w-full py-3 bg-[#113121] hover:bg-emerald-900 text-white rounded-2xl text-xs font-bold shadow transition-colors"
              >
                Discuss &quot;{activeCondition.name}&quot; with Dr. Hassan
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
