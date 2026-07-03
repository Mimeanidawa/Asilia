import React, { useState } from "react";
import { ARTICLES, Article } from "../data";
import { BookOpen, Clock, ChevronRight, X, Heart, MessageSquare } from "lucide-react";

export default function LearnScreen() {
  const [selectedCat, setSelectedCat] = useState<"All" | "Health Tips" | "Herbs 101" | "Nutrition">("All");
  const [activeArticle, setActiveArticle] = useState<Article | null>(null);

  const filteredArticles = selectedCat === "All"
    ? ARTICLES
    : ARTICLES.filter((a) => a.category === selectedCat);

  const featuredArticle = ARTICLES[0];

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] overflow-y-auto pb-20 select-none">
      {/* Top Header */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03] shrink-0">
        <div className="flex items-center space-x-2">
          <BookOpen className="w-5 h-5 text-emerald-800" />
          <span className="text-sm font-black font-sans uppercase tracking-tight">Learn</span>
        </div>
      </div>

      {/* Category Pills */}
      <div className="px-5 py-3.5 bg-white flex space-x-2 overflow-x-auto scrollbar-none shrink-0 border-b border-emerald-800/[0.03]">
        {(["All", "Health Tips", "Herbs 101", "Nutrition"] as const).map((cat) => (
          <button
            key={cat}
            onClick={() => setSelectedCat(cat)}
            className={`px-4 py-2 rounded-full text-[10px] font-extrabold tracking-tight transition-all shrink-0 ${
              selectedCat === cat
                ? "bg-[#113121] text-white shadow-sm"
                : "bg-emerald-50/50 text-[#113121] border border-emerald-800/10 hover:bg-emerald-50"
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {selectedCat === "All" && (
        /* Featured Story Billboard */
        <div className="p-5 shrink-0">
          <div className="relative rounded-2xl overflow-hidden border border-emerald-800/10 shadow-sm bg-white">
            <div className="h-40 w-full relative">
              <img
                src={featuredArticle.imageUrl}
                alt={featuredArticle.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-black/20 to-transparent" />
              <span className="absolute top-3 left-3 bg-[#836C45] text-white px-2.5 py-0.5 text-[8px] font-extrabold uppercase rounded-full tracking-wider">
                Featured Cover
              </span>
            </div>
            <div className="p-4 space-y-2">
              <h4 className="text-base font-black font-sans tracking-tight text-[#113121] leading-tight">
                {featuredArticle.title}
              </h4>
              <p className="text-[11px] text-gray-500 line-clamp-2 leading-relaxed font-sans">
                {featuredArticle.summary}
              </p>
              <div className="flex items-center justify-between pt-2">
                <span className="text-[9px] font-mono text-gray-400 flex items-center">
                  <Clock className="w-3 h-3 mr-1" /> {featuredArticle.readTime}
                </span>
                <button
                  onClick={() => setActiveArticle(featuredArticle)}
                  className="text-[10px] font-extrabold text-[#113121] hover:underline flex items-center"
                >
                  Read Article <ChevronRight className="w-3.5 h-3.5 ml-0.5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Main Articles List grid */}
      <div className="px-5 space-y-3">
        <h4 className="text-xs font-black uppercase tracking-wider text-gray-400">
          Recent Articles ({filteredArticles.length})
        </h4>

        <div className="space-y-3">
          {filteredArticles.map((article) => (
            <div
              key={article.id}
              onClick={() => setActiveArticle(article)}
              className="flex p-2.5 bg-white border border-emerald-800/[0.04] rounded-2xl shadow-sm hover:border-emerald-800/20 cursor-pointer transition-all"
            >
              <div className="w-[85px] h-[85px] rounded-xl overflow-hidden shrink-0 border border-emerald-800/10">
                <img src={article.imageUrl} alt={article.title} className="w-full h-full object-cover" />
              </div>
              <div className="ml-3 flex-1 min-w-0 flex flex-col justify-between py-1">
                <div className="space-y-1">
                  <span className="text-[8px] font-extrabold uppercase tracking-widest text-[#836C45]">
                    {article.category}
                  </span>
                  <h5 className="text-xs font-bold font-sans text-[#113121] truncate leading-tight">
                    {article.title}
                  </h5>
                  <p className="text-[10px] text-gray-400 line-clamp-2 leading-snug">
                    {article.summary}
                  </p>
                </div>
                <div className="flex items-center text-[8px] font-mono text-gray-400">
                  <Clock className="w-2.5 h-2.5 mr-1" />
                  <span>{article.readTime}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Interactive Modal Reader Overlay */}
      {activeArticle && (
        <div className="absolute inset-0 bg-[#FAF7F2] z-40 flex flex-col animate-in fade-in-25 duration-200">
          {/* Top Header navbar */}
          <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03]">
            <button
              onClick={() => setActiveArticle(null)}
              className="p-1.5 rounded-full hover:bg-emerald-50 text-[#113121]"
            >
              <X className="w-5 h-5" />
            </button>
            <span className="text-[10px] font-extrabold tracking-widest text-emerald-800 uppercase">
              Reading Hub
            </span>
            <div className="w-5" />
          </div>

          <div className="flex-1 overflow-y-auto pb-10">
            <div className="h-56 w-full relative">
              <img
                src={activeArticle.imageUrl}
                alt={activeArticle.title}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#FAF7F2] to-transparent" />
            </div>

            <div className="px-5 -mt-8 relative space-y-4">
              <div className="space-y-1.5 bg-white p-4 rounded-2xl border border-emerald-800/[0.03] shadow-sm">
                <span className="text-[9px] font-extrabold uppercase tracking-widest text-[#836C45]">
                  {activeArticle.category}
                </span>
                <h3 className="text-lg font-black font-sans text-[#113121] leading-tight-snug">
                  {activeArticle.title}
                </h3>
                <div className="flex items-center text-[10px] font-mono text-gray-400 mt-1">
                  <Clock className="w-3.5 h-3.5 mr-1 text-[#836C45]" />
                  <span>{activeArticle.readTime}</span>
                </div>
              </div>

              {/* Bold Summary Card */}
              <div className="p-4 bg-emerald-50/40 border-l-[3.5px] border-emerald-800 text-xs font-bold text-emerald-950 font-sans italic leading-relaxed rounded-r-xl">
                &quot;{activeArticle.summary}&quot;
              </div>

              {/* Detailed Reading text */}
              <p className="text-xs text-gray-650 leading-relaxed font-sans font-medium whitespace-pre-wrap px-1">
                {activeArticle.content}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
