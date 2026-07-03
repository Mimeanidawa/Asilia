import React from "react";
import { Leaf, BookOpen, MessageSquare, ShieldCheck, Heart, Sparkles } from "lucide-react";

export default function SidebarBranding() {
  return (
    <div className="flex flex-col justify-between h-full py-6 pr-0 md:pr-8 text-[#113121] select-none max-w-md w-full mx-auto md:mx-0">
      {/* Brand Header */}
      <div>
        <div className="flex items-center space-x-3 mb-8">
          <div className="w-12 h-12 rounded-full border border-emerald-800/20 bg-emerald-50 flex items-center justify-center text-[#113121] shadow-sm">
            <Leaf className="w-6 h-6 stroke-[1.8]" />
          </div>
          <div>
            <h1 className="text-2xl font-bold tracking-tight font-serif text-[#113121] flex items-center">
              Dawa Asili
            </h1>
            <p className="text-[10px] tracking-widest text-[#836C45] font-semibold uppercase leading-none">
              Natural Healing. Real Results.
            </p>
          </div>
        </div>

        {/* Hero Copy */}
        <div className="space-y-4 mb-8">
          <h2 className="text-4xl md:text-5xl font-extrabold tracking-tight font-serif text-[#113121] leading-tight">
            Heal Naturally, <br />
            <span className="italic font-normal text-emerald-800">Live Better.</span>
          </h2>
          <p className="text-sm text-gray-700/80 leading-relaxed font-sans">
            Your trusted companion for native herbal remedies, wellness tips, and a healthier, revitalized you. Preserving ancient African healing wisdom.
          </p>
        </div>

        {/* Hero Features List */}
        <div className="space-y-4 mb-8">
          {/* Feature 1 */}
          <div className="flex items-start space-x-4 p-3 rounded-2xl bg-white border border-emerald-800/[0.04] shadow-[0_4px_24px_rgba(17,49,33,0.02)] hover:shadow-[0_8px_30px_rgba(17,49,33,0.04)] transition-all duration-300">
            <div className="w-10 h-10 rounded-xl bg-[#113121] flex items-center justify-center text-[#FAF7F2] shrink-0 shadow-inner">
              <Leaf className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-[#113121]">100% Natural Remedies</h4>
              <p className="text-xs text-gray-500 mt-0.5">Discover effective, time-tested herbal treatments.</p>
            </div>
          </div>

          {/* Feature 2 */}
          <div className="flex items-start space-x-4 p-3 rounded-2xl bg-white border border-emerald-800/[0.04] shadow-[0_4px_24px_rgba(17,49,33,0.02)] hover:shadow-[0_8px_30px_rgba(17,49,33,0.04)] transition-all duration-300">
            <div className="w-10 h-10 rounded-xl bg-[#113121] flex items-center justify-center text-[#FAF7F2] shrink-0 shadow-inner">
              <BookOpen className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-[#113121]">Health & Wellness Tips</h4>
              <p className="text-xs text-gray-500 mt-0.5">Learn and live an authentic, vital, disease-free lifestyle.</p>
            </div>
          </div>

          {/* Feature 3 */}
          <div className="flex items-start space-x-4 p-3 rounded-2xl bg-white border border-emerald-800/[0.04] shadow-[0_4px_24px_rgba(17,49,33,0.02)] hover:shadow-[0_8px_30px_rgba(17,49,33,0.04)] transition-all duration-300">
            <div className="w-10 h-10 rounded-xl bg-[#113121] flex items-center justify-center text-[#FAF7F2] shrink-0 shadow-inner">
              <MessageSquare className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-[#113121]">Ask an Expert</h4>
              <p className="text-xs text-gray-500 mt-0.5">Receive personal consultation from real herbal specialists.</p>
            </div>
          </div>
        </div>

        {/* Value Proposition Badge */}
        <div className="inline-flex items-center space-x-2.5 px-4 py-2 rounded-full border border-emerald-800/20 bg-emerald-50 text-[#113121] text-xs font-semibold mb-6">
          <Sparkles className="w-3.5 h-3.5 text-[#836C45]" />
          <span>Rooted in Nature. Backed by Tradition.</span>
        </div>
      </div>

      {/* Trust Badges and Downloads */}
      <div className="space-y-6 pt-6 border-t border-emerald-800/10">
        <div className="grid grid-cols-4 gap-2 text-center">
          <div className="flex flex-col items-center">
            <Leaf className="w-5 h-5 text-emerald-700 mb-1" />
            <span className="text-[10px] font-bold tracking-tight text-[#113121]">Natural</span>
          </div>
          <div className="flex flex-col items-center">
            <ShieldCheck className="w-5 h-5 text-emerald-700 mb-1" />
            <span className="text-[10px] font-bold tracking-tight text-[#113121]">Safe</span>
          </div>
          <div className="flex flex-col items-center">
            <Heart className="w-5 h-5 text-emerald-700 mb-1" />
            <span className="text-[10px] font-bold tracking-tight text-[#113121]">Trusted</span>
          </div>
          <div className="flex flex-col items-center">
            <Sparkles className="w-5 h-5 text-emerald-700 mb-1" />
            <span className="text-[10px] font-bold tracking-tight text-[#113121]">Effective</span>
          </div>
        </div>

        {/* App store downloads */}
        <div>
          <h4 className="text-xs font-bold text-[#113121] uppercase tracking-wider mb-2.5">
            Download Dawa Asili
          </h4>
          <div className="flex items-center space-x-3">
            {/* Apple button mockup */}
            <a
              href="#download"
              className="flex items-center space-x-2 bg-[#113121] hover:bg-[#1c4731] transition-colors rounded-xl px-4 py-2 text-[#FAF7F2] w-1/2"
              onClick={(e) => e.preventDefault()}
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M18.71,19.5C17.88,20.74,17,21.95,15.66,21.97C14.32,22,13.89,21.18,12.37,21.18C10.84,21.18,10.37,21.95,9.1,22C7.79,22.05,6.8,20.68,5.96,19.47C4.25,17,2.94,12.45,4.7,9.39C5.57,7.87,7.13,6.91,8.82,6.88C10.1,6.86,11.32,7.75,12.11,7.75C12.9,7.75,14.38,6.68,15.92,6.84C16.57,6.87,18.39,7.1,19.56,8.82C19.47,8.88,17.39,10.1,17.41,12.63C17.44,15.65,20.06,16.66,20.1,16.67C20.08,16.74,19.67,18.11,18.71,19.5M15.97,4.17C16.63,3.37,17.07,2.28,16.95,1C16,1.04,14.9,1.6,14.24,2.38C13.68,3.04,13.19,4.14,13.34,5.39C14.39,5.47,15.4,4.88,15.97,4.17Z" />
              </svg>
              <div className="text-left font-sans">
                <p className="text-[8px] uppercase tracking-wide opacity-80 leading-tight">Download on the</p>
                <p className="text-xs font-bold leading-tight -mt-0.5">App Store</p>
              </div>
            </a>

            {/* Google Play button mockup */}
            <a
              href="#download"
              className="flex items-center space-x-2 bg-[#113121] hover:bg-[#1c4731] transition-colors rounded-xl px-4 py-2 text-[#FAF7F2] w-1/2"
              onClick={(e) => e.preventDefault()}
            >
              <svg className="w-5 h-5 fill-current" viewBox="0 0 24 24">
                <path d="M3,5.27V18.73L16.55,12L3,5.27M17.87,11.33L19.5,12.15L17.87,12.97L16.55,12L17.87,11.33M3,3.41C3.33,3.41,3.67,3.5,4,3.65L20.13,11.72C20.67,12,20.67,12.5,20.13,12.78L4,20.85C3.67,21,3.33,21.09,3,21.09C2.45,21.09,2,20.64,2,20.09V4.41C2,3.86,2.45,3.41,3,3.41Z" />
              </svg>
              <div className="text-left font-sans">
                <p className="text-[8px] uppercase tracking-wide opacity-80 leading-tight">GET IT ON</p>
                <p className="text-xs font-bold leading-tight -mt-0.5">Google Play</p>
              </div>
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}
