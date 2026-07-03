import React, { useState } from "react";
import { useApp, Reminder } from "../context/AppContext";
import { HERBS } from "../data";
import { User, Heart, Clock, Bell, Settings, Info, LogOut, ChevronRight, X, Plus, Trash2, Power, PowerOff, Sparkles } from "lucide-react";

export default function ProfileScreen() {
  const { 
    favorites, 
    reminders, 
    questions, 
    toggleReminder, 
    deleteReminder, 
    addReminder, 
    navigate 
  } = useApp();

  const [activeTab, setActiveTab] = useState<"favorites" | "reminders" | "questions" | "about" | null>(null);
  
  // New Reminder state inputs
  const [showAddReminder, setShowAddReminder] = useState(false);
  const [remTitle, setRemTitle] = useState("");
  const [remTime, setRemTime] = useState("08:00 AM");
  const [remHerb, setRemHerb] = useState("neem");

  const [settings, setSettings] = useState({
    pushNotifications: true,
    offlineCache: false,
    usePremiumAIVoice: false
  });

  const handleCreateReminder = (e: React.FormEvent) => {
    e.preventDefault();
    if (!remTitle.trim()) return;
    addReminder(remTitle, remTime, remHerb);
    setRemTitle("");
    setShowAddReminder(false);
  };

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] overflow-y-auto pb-20 select-none">
      {/* Top Header */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03] shrink-0">
        <div className="flex items-center space-x-2">
          <User className="w-4 h-4 text-emerald-800" />
          <span className="text-sm font-black font-sans uppercase tracking-tight">My Profile</span>
        </div>
      </div>

      {/* User Header Profile Card */}
      <div className="p-5 bg-white border-b border-emerald-800/[0.03] space-y-4">
        <div className="flex items-center space-x-4">
          <div className="relative shrink-0">
            {/* Beautiful female profile picture matching Asha Juma */}
            <img
              src="https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&q=80&w=200"
              alt="Asha Juma"
              className="w-16 h-16 rounded-full object-cover border-2 border-[#836C45]/30"
            />
            <span className="absolute bottom-0.5 right-0.5 w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full" />
          </div>
          <div>
            <h3 className="text-base font-black font-sans tracking-tight text-[#113121]">Asha Juma</h3>
            <p className="text-xs text-gray-400 font-semibold lowercase">asha.juma@email.com</p>
            <span className="inline-block mt-1.5 text-[8px] bg-emerald-50 text-emerald-950 font-black px-2 py-0.5 rounded-full uppercase tracking-wider">
              Native Seeker membership
            </span>
          </div>
        </div>
      </div>

      {/* Primary Navigation Menu list */}
      <div className="p-5 space-y-3">
        <h4 className="text-[10px] font-black uppercase text-gray-400 tracking-wider">My Health Desk</h4>

        {/* Favorites menu */}
        <button
          onClick={() => setActiveTab("favorites")}
          className="w-full flex items-center justify-between p-3.5 bg-white border border-emerald-800/[0.03] hover:border-emerald-800/10 rounded-2xl shadow-sm transition-all"
        >
          <div className="flex items-center space-x-3 text-[#113121]">
            <Heart className="w-4.5 h-4.5 text-red-500 shrink-0" />
            <span className="text-xs font-bold">My Saved Herbs</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-[10px] bg-red-50 text-red-600 font-extrabold px-2 py-0.5 rounded-full">
              {favorites.length}
            </span>
            <ChevronRight className="w-4.5 h-4.5 text-emerald-800/20" />
          </div>
        </button>

        {/* Reminders menu */}
        <button
          onClick={() => setActiveTab("reminders")}
          className="w-full flex items-center justify-between p-3.5 bg-white border border-emerald-800/[0.03] hover:border-emerald-800/10 rounded-2xl shadow-sm transition-all"
        >
          <div className="flex items-center space-x-3 text-[#113121]">
            <Bell className="w-4.5 h-4.5 text-[#836C45] shrink-0" />
            <span className="text-xs font-bold">Reminders Alerts</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-[10px] bg-amber-50 text-amber-950 font-extrabold px-2 py-0.5 rounded-full">
              {reminders.filter((r) => r.active).length} active
            </span>
            <ChevronRight className="w-4.5 h-4.5 text-emerald-800/20" />
          </div>
        </button>

        {/* Questions menu */}
        <button
          onClick={() => setActiveTab("questions")}
          className="w-full flex items-center justify-between p-3.5 bg-white border border-emerald-800/[0.03] hover:border-emerald-800/10 rounded-2xl shadow-sm transition-all"
        >
          <div className="flex items-center space-x-3 text-[#113121]">
            <Clock className="w-4.5 h-4.5 text-blue-500 shrink-0" />
            <span className="text-xs font-bold">Consultation History</span>
          </div>
          <div className="flex items-center space-x-2">
            <span className="text-[10px] bg-blue-50 text-blue-900 font-extrabold px-2 py-0.5 rounded-full">
              {questions.length} cases
            </span>
            <ChevronRight className="w-4.5 h-4.5 text-emerald-800/20" />
          </div>
        </button>

        {/* Settings collapsible list */}
        <div className="p-4 bg-white border border-emerald-800/[0.03] rounded-2xl shadow-sm space-y-3 mt-4">
          <div className="flex items-center space-x-2 text-emerald-800 mb-2">
            <Settings className="w-4 h-4 text-[#836C45]" />
            <h5 className="text-[9px] font-black tracking-wider uppercase">Application Settings</h5>
          </div>

          {[
            { key: "pushNotifications", label: "Push Notification Alerts", desc: "For healing alerts" },
            { key: "offlineCache", label: "Offline Remedies Cache", desc: "Dawa directory offline" }
          ].map((item) => (
            <div key={item.key} className="flex items-center justify-between py-1 border-b border-emerald-800/[0.02] last:border-0">
              <div className="min-w-0">
                <p className="text-xs font-bold text-[#113121]">{item.label}</p>
                <p className="text-[9px] text-gray-400 mt-0.5">{item.desc}</p>
              </div>
              <button
                onClick={() => setSettings(prev => ({ ...prev, [item.key]: !prev[item.key as keyof typeof prev] }))}
                className={`w-10 h-6 flex items-center rounded-full p-0.5 transition-colors cursor-pointer ${
                  settings[item.key as keyof typeof settings] ? "bg-emerald-800" : "bg-gray-300"
                }`}
              >
                <div
                  className={`bg-white w-5 h-5 rounded-full shadow-md transform duration-200 ${
                    settings[item.key as keyof typeof settings] ? "translate-x-4" : ""
                  }`}
                />
              </button>
            </div>
          ))}
        </div>

        {/* About application support trigger */}
        <button
          onClick={() => setActiveTab("about")}
          className="w-full flex items-center justify-between p-3.5 bg-white border border-emerald-800/[0.03] hover:border-emerald-800/10 rounded-2xl shadow-sm transition-all mt-4"
        >
          <div className="flex items-center space-x-3 text-[#113121]">
            <Info className="w-4.5 h-4.5 text-[#113121] shrink-0" />
            <span className="text-xs font-bold">About Dawa Asili & Disclaimer</span>
          </div>
          <ChevronRight className="w-4.5 h-4.5 text-emerald-800/20" />
        </button>

        {/* Logout link */}
        <button
          onClick={() => alert("Simulated profile reset successfully. State restored to original default of Dawa Asili.")}
          className="w-full flex items-center justify-between p-3.5 bg-red-50 border border-red-200 text-red-800 hover:bg-red-100 rounded-2xl transition-all mt-4"
        >
          <div className="flex items-center space-x-3">
            <LogOut className="w-4.5 h-4.5 text-red-700 shrink-0" />
            <span className="text-xs font-extrabold text-red-800">Reset Local Profile State</span>
          </div>
          <ChevronRight className="w-4.5 h-4.5 text-red-200" />
        </button>
      </div>

      {/* Profile Detail Overlays/Drawers */}
      {activeTab && (
        <div className="absolute inset-0 bg-[#FAF7F2] z-30 flex flex-col animate-in slide-in-from-right duration-250 pb-16">
          {/* Sub Header bar */}
          <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03] shrink-0">
            <button
              onClick={() => setActiveTab(null)}
              className="p-1.5 rounded-full hover:bg-emerald-50 text-gray-500 hover:text-[#113121]"
            >
              <X className="w-5 h-5" />
            </button>
            <span className="text-[10px] font-extrabold tracking-widest text-emerald-800 uppercase">
              {activeTab} directory
            </span>
            <div className="w-5" />
          </div>

          <div className="flex-1 overflow-y-auto p-5 space-y-4">
            {/* SAVED FAVORITES HUB */}
            {activeTab === "favorites" && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-black text-[#113121]">My Favorite Botanical Herbs</h4>
                  <span className="text-[10px] bg-red-50 text-red-600 px-2.5 py-1 rounded-full font-bold">
                    {favorites.length} herbs
                  </span>
                </div>

                {favorites.length === 0 ? (
                  <div className="py-20 text-center text-gray-400">
                    <Heart className="w-10 h-10 mx-auto opacity-20 mb-2 text-red-500" />
                    <p className="text-sm font-medium">Your natural botanical cabinet is empty.</p>
                  </div>
                ) : (
                  <div className="grid grid-cols-1 gap-2.5">
                    {favorites.map((fid) => {
                      const h = HERBS.find((herb) => herb.id === fid);
                      if (!h) return null;
                      return (
                        <div
                          key={h.id}
                          onClick={() => {
                            setActiveTab(null);
                            navigate("herb-details", { herbId: h.id });
                          }}
                          className="flex items-center space-x-3 p-3 bg-white border border-emerald-800/[0.04] rounded-2xl shadow-sm cursor-pointer hover:border-emerald-800/10 transition-colors"
                        >
                          <img src={h.imageUrl} alt={h.name} className="w-12 h-12 rounded-xl object-cover" />
                          <div className="flex-1 min-w-0">
                            <p className="text-xs font-extrabold text-[#113121]">{h.name}</p>
                            <p className="text-[9px] text-gray-400 italic truncate">{h.scientificName}</p>
                          </div>
                          <ChevronRight className="w-4 h-4 text-emerald-800/30" />
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* REMINDERS LIST WITH SCHEDULING FORM */}
            {activeTab === "reminders" && (
              <div className="space-y-4">
                <div className="flex items-center justify-between">
                  <h4 className="text-sm font-black text-[#113121]">My Active Alerts</h4>
                  <button
                    onClick={() => setShowAddReminder(true)}
                    className="p-2 bg-[#113121] hover:bg-teal-950 text-white rounded-full flex items-center justify-center shadow-sm"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>

                {showAddReminder && (
                  <form onSubmit={handleCreateReminder} className="bg-white p-4 rounded-2xl border border-emerald-800/15 space-y-4 animate-in fade-in zoom-in-95 duration-100">
                    <div className="flex justify-between items-center pb-2 border-b border-emerald-800/[0.04]">
                      <h5 className="text-[10px] font-black uppercase tracking-wider text-[#113121]">Add Dose Reminder</h5>
                      <button type="button" onClick={() => setShowAddReminder(false)} className="text-gray-400">
                        <X className="w-4 h-4" />
                      </button>
                    </div>

                    <div className="space-y-1.5">
                      <label className="text-[9px] font-black uppercase text-gray-400">Reminder Action</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. Sip warm Mwarobaini Leaf Tea"
                        value={remTitle}
                        onChange={(e) => setRemTitle(e.target.value)}
                        className="w-full bg-emerald-50/20 border border-emerald-800/10 rounded-xl px-3 py-2.5 text-xs text-[#113121] placeholder-emerald-800/35 focus:outline-none"
                      />
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black uppercase text-gray-400">Alert Daily Time</label>
                        <select
                          value={remTime}
                          onChange={(e) => setRemTime(e.target.value)}
                          className="w-full bg-emerald-50/20 border border-emerald-800/10 rounded-xl px-2.5 py-2.5 text-xs text-[#113121]"
                        >
                          {["06:00 AM", "08:00 AM", "01:00 PM", "04:00 PM", "08:00 PM", "10:00 PM"].map((t) => (
                            <option key={t} value={t}>{t}</option>
                          ))}
                        </select>
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-[9px] font-black uppercase text-gray-400">Matched Botanical</label>
                        <select
                          value={remHerb}
                          onChange={(e) => setRemHerb(e.target.value)}
                          className="w-full bg-emerald-50/20 border border-emerald-800/10 rounded-xl px-2.5 py-2.5 text-xs text-[#113121]"
                        >
                          {HERBS.map((h) => (
                            <option key={h.id} value={h.id}>{h.name}</option>
                          ))}
                        </select>
                      </div>
                    </div>

                    <button
                      type="submit"
                      className="w-full py-2.5 bg-[#113121] hover:bg-emerald-950 text-white rounded-xl text-xs font-bold"
                    >
                      Save Healing Reminder
                    </button>
                  </form>
                )}

                {reminders.length === 0 ? (
                  <div className="py-20 text-center text-gray-400">
                    <p className="text-sm">No regular intake schedules scheduled.</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {reminders.map((rem) => {
                      const matchedHerb = HERBS.find((h) => h.id === rem.herbId);
                      return (
                        <div
                          key={rem.id}
                          className="flex items-center justify-between p-3.5 bg-white border border-emerald-800/[0.03] rounded-2xl shadow-sm"
                        >
                          <div className="min-w-0 pr-2">
                            <p className="text-xs font-black text-[#113121]">{rem.title}</p>
                            <p className="text-[10px] text-gray-400 flex items-center mt-1">
                              <span className="font-mono text-emerald-800 mr-2 font-bold">{rem.time}</span>
                              {matchedHerb && (
                                <span className="text-[8px] bg-emerald-50 text-emerald-900 border border-emerald-800/10 px-1.5 py-0.5 rounded">
                                  {matchedHerb.name}
                                </span>
                              )}
                            </p>
                          </div>
                          
                          <div className="flex items-center space-x-2">
                            {/* Toggle Switch */}
                            <button
                              onClick={() => toggleReminder(rem.id)}
                              className={`p-1 rounded-full transition-colors ${
                                rem.active ? "bg-emerald-50 hover:bg-emerald-100 text-emerald-800" : "bg-gray-100 hover:bg-gray-200 text-gray-400"
                              }`}
                            >
                              {rem.active ? <Power className="w-4 h-4" /> : <PowerOff className="w-4 h-4" />}
                            </button>

                            {/* Delete Alert */}
                            <button
                              onClick={() => deleteReminder(rem.id)}
                              className="p-1 text-red-300 hover:text-red-700 hover:bg-red-50 rounded"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* CONSULTATION HISTORY RECORD */}
            {activeTab === "questions" && (
              <div className="space-y-3">
                <h4 className="text-sm font-black text-[#113121]">Diagnosed Cases & Symptoms</h4>

                {questions.length === 0 ? (
                  <div className="py-20 text-center text-gray-450 font-medium">
                    <p className="text-sm">No previous digital cases or expert consultations log files are found.</p>
                  </div>
                ) : (
                  <div className="space-y-3">
                    {questions.map((q) => (
                      <div key={q.id} className="p-4 bg-white border border-emerald-800/[0.03] rounded-2xl shadow-sm space-y-2.5">
                        <div className="flex justify-between items-start">
                          <span className="text-[8px] font-bold text-gray-400 uppercase tracking-wider">{q.timestamp}</span>
                          <span className="text-[8px] bg-emerald-50 text-emerald-900 font-extrabold px-2 py-0.5 rounded-full uppercase">Case closed</span>
                        </div>
                        <p className="text-xs font-bold text-[#113121] leading-snug">Q: &quot;{q.query}&quot;</p>
                        <div className="text-[11px] text-gray-650 leading-relaxed pl-2.5 border-l-2 border-[#836C45] whitespace-pre-line bg-[#FAF7F2]/40 p-2 rounded-r-xl">
                          {q.answer}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}

            {/* TRADITIONAL BOTANICAL MEDICINE DISCLAIMER */}
            {activeTab === "about" && (
              <div className="bg-white p-5 rounded-2xl border border-emerald-800/[0.03] shadow-sm space-y-4 font-sans text-xs">
                <div className="text-center pb-2 border-b border-emerald-800/[0.04]">
                  <Sparkles className="w-7 h-7 mx-auto text-[#836C45] mb-1.5 animate-pulse" />
                  <p className="text-sm font-black text-[#113121]">Our Mission: Preserving Wisdom</p>
                  <p className="text-[9px] text-gray-400 mt-0.5">Dawa Asili Platform • Ver 4.0</p>
                </div>

                <p className="leading-relaxed text-gray-650 font-semibold">
                  At **Dawa Asili**, we are committed to compiling, researching, and sharing traditional African herbal remedies. Native plants are magnificent partners in holistic metabolic balance, tissue cooling, and preventative wellness.
                </p>

                <div className="p-3 bg-red-50 border border-red-200 text-red-950 rounded-xl text-[10px] space-y-1.5 font-medium">
                  <p className="font-extrabold text-red-900 uppercase tracking-wider">Clinical Regulatory Notice</p>
                  <p className="leading-normal text-gray-500 font-semibold">
                    1. The botanical therapies, leaves infusions, and remedies referenced here are sourced from regional folk heritage and are purely for educational wellness guidance.
                  </p>
                  <p className="leading-normal text-gray-500 font-semibold">
                    2. These options are **NOT** checked or reviewed by the Food and Drug Administration or strict Western Clinical Ministries. 
                  </p>
                  <p className="leading-normal text-gray-500 font-semibold">
                    3. Never discontinue any clinical prescriptions or treatment paths without consultation with qualified doctors.
                  </p>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
