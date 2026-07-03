import React from "react";
import { useApp } from "../context/AppContext";
import { HERBS } from "../data";
import { ArrowLeft, Heart, CheckCircle2, FlaskConical, AlertTriangle, Sparkles } from "lucide-react";

export default function HerbDetailsScreen() {
  const { selectedHerbId, goBack, toggleFavorite, isFavorite, navigate } = useApp();

  const herb = HERBS.find((h) => h.id === selectedHerbId) || HERBS[0];
  const favorited = isFavorite(herb.id);

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] overflow-y-auto pb-20 select-none">
      {/* Top Navigation */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03]">
        <button
          onClick={goBack}
          className="p-1.5 rounded-full hover:bg-emerald-50 text-[#113121]"
        >
          <ArrowLeft className="w-5 h-5" />
        </button>
        <span className="text-sm font-black font-sans tracking-tight uppercase">Herb Details</span>
        <button
          onClick={() => toggleFavorite(herb.id)}
          className={`p-1.5 rounded-full transition-colors ${
            favorited ? "bg-red-50 text-red-600" : "hover:bg-emerald-50 text-[#113121]"
          }`}
        >
          <Heart className={`w-5 h-5 ${favorited ? "fill-current" : ""}`} />
        </button>
      </div>

      {/* Main Herb Image */}
      <div className="relative h-48 w-full bg-emerald-100 shrink-0">
        <img
          src={herb.imageUrl}
          alt={herb.name}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-x-0 bottom-0 h-16 bg-gradient-to-t from-black/40 to-transparent" />
        <span className="absolute bottom-3 right-4 bg-[#836C45] text-white px-2.5 py-1 text-[9px] font-bold tracking-widest rounded-full uppercase shadow">
          100% Natural
        </span>
      </div>

      {/* Core Body Container */}
      <div className="p-5 space-y-5">
        {/* Title Block */}
        <div className="space-y-1">
          <div className="flex items-center space-x-2">
            <h3 className="text-xl font-black font-sans tracking-tight">{herb.name}</h3>
            {herb.localName && (
              <span className="text-[10px] bg-emerald-100/60 text-emerald-900 border border-emerald-800/10 px-2 py-0.5 rounded-full font-bold">
                {herb.localName}
              </span>
            )}
          </div>
          <p className="text-xs text-gray-400 font-mono italic">{herb.scientificName}</p>
        </div>

        {/* Used For Badges */}
        <div className="space-y-1.5">
          <p className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Used For</p>
          <div className="flex flex-wrap gap-1.5">
            {herb.usedFor.map((use, idx) => (
              <span
                key={idx}
                className="text-[10px] font-bold bg-white text-[#113121] border border-emerald-800/10 px-2.5 py-1 rounded-xl"
              >
                {use}
              </span>
            ))}
          </div>
        </div>

        {/* Description */}
        <div className="space-y-1.5">
          <h4 className="text-xs font-extrabold text-[#113121]/50 uppercase tracking-wider">About</h4>
          <p className="text-xs text-gray-600 leading-relaxed font-sans">{herb.description}</p>
        </div>

        {/* Benefits List */}
        <div className="space-y-2.5">
          <h4 className="text-xs font-extrabold text-gray-400 uppercase tracking-wider">Benefits</h4>
          <div className="grid grid-cols-1 gap-2">
            {herb.benefits.map((benefit, idx) => (
              <div key={idx} className="flex items-center space-x-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
                <span className="text-xs font-bold text-[#113121]">{benefit}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Preparation Guidelines */}
        <div className="p-4 rounded-2xl bg-white border border-emerald-800/[0.04] space-y-2">
          <div className="flex items-center space-x-2 text-[#836C45]">
            <FlaskConical className="w-4 h-4" />
            <h5 className="text-xs font-extrabold uppercase tracking-wider">How to Use</h5>
          </div>
          <p className="text-xs text-gray-600 leading-normal font-sans">{herb.howToUse}</p>
        </div>

        {/* Traditional Caution Advice */}
        <div className="flex items-start space-x-2 p-3.5 rounded-xl bg-orange-50 border border-orange-200/50 text-orange-950">
          <AlertTriangle className="w-4 h-4 text-orange-600 shrink-0 mt-0.5" />
          <p className="text-[9px] text-gray-500 font-medium leading-normal shrink">
            **Caution**: Herbal infusions are highly active naturally. Start with a smaller mug to check body compatibility. Consistently monitor symptoms.
          </p>
        </div>

        {/* View Alternate Remedies */}
        <button
          onClick={() => navigate("conditions")}
          className="w-full py-3 bg-[#113121] hover:bg-emerald-950 text-[#FAF7F2] font-extrabold text-xs rounded-2xl flex items-center justify-center space-x-2 shadow-sm transition-colors"
        >
          <Sparkles className="w-4 h-4 text-[#836C45]" />
          <span>View More Remedies</span>
        </button>
      </div>
    </div>
  );
}
