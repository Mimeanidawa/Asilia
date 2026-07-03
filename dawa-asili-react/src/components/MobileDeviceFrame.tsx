import React from "react";
import { useApp } from "../context/AppContext";
import HomeScreen from "./HomeScreen";
import HerbDetailsScreen from "./HerbDetailsScreen";
import AskExpertScreen from "./AskExpertScreen";
import LearnScreen from "./LearnScreen";
import ConditionsScreen from "./ConditionsScreen";
import ProfileScreen from "./ProfileScreen";
import { Home, BookOpen, MessageSquare, User, Activity, Leaf } from "lucide-react";

export default function MobileDeviceFrame() {
  const { activeScreen, navigate } = useApp();

  const renderActiveScreen = () => {
    switch (activeScreen) {
      case "home":
        return <HomeScreen />;
      case "herb-details":
        return <HerbDetailsScreen />;
      case "ask-expert":
        return <AskExpertScreen />;
      case "learn":
        return <LearnScreen />;
      case "conditions":
        return <ConditionsScreen />;
      case "profile":
        return <ProfileScreen />;
      default:
        return <HomeScreen />;
    }
  };

  return (
    <div className="relative mx-auto w-full max-w-[390px] h-[780px] bg-[#FAF7F2] rounded-[48px] shadow-[0_24px_64px_rgba(11,35,23,0.18)] border-[10px] border-[#0C2016] overflow-hidden select-none flex flex-col font-sans ring-8 ring-emerald-950/5">
      
      {/* Dynamic Notch / Island */}
      <div className="absolute top-0 inset-x-0 h-7 z-50 flex justify-center pointer-events-none">
        <div className="w-28 h-4.5 bg-[#0C2016] rounded-b-2xl flex items-center justify-around px-3">
          {/* Mock Camera lens */}
          <span className="w-1.5 h-1.5 rounded-full bg-emerald-950" />
          <span className="w-3.5 h-1 bg-emerald-950 rounded-full" />
        </div>
      </div>

      {/* Top Mobile Status Bar (9:41, Icons) */}
      <div className="bg-white px-6 pt-7 pb-2.5 flex justify-between items-center text-[#113121] text-[11px] font-black tracking-tight shrink-0 select-none border-b border-emerald-800/[0.02]">
        <span>9:41</span>
        
        {/* Signal, Wifi, Battery */}
        <div className="flex items-center space-x-1.5 scale-95 origin-right">
          {/* Signal */}
          <div className="flex items-end space-x-0.5 h-2.5">
            <span className="w-[1.5px] h-[3px] bg-[#113121] rounded-full" />
            <span className="w-[1.5px] h-[5px] bg-[#113121] rounded-full" />
            <span className="w-[1.5px] h-[7px] bg-[#113121] rounded-full" />
            <span className="w-[1.5px] h-[9px] bg-[#113121] rounded-full opacity-40" />
          </div>
          {/* Wifi icon mock */}
          <svg className="w-3 h-3 fill-current" viewBox="0 0 24 24">
            <path d="M12,21L15.6,16.2C14.6,15.4 13.3,15 12,15C10.7,15 9.4,15.4 8.4,16.2L12,21M12,3A9,9 0 0,0 3,12C3,14.5 4,16.8 5.6,18.4L12,24L18.4,18.4C20,16.8 21,14.5 21,12A9,9 0 0,0 12,3Z" />
          </svg>
          {/* Battery */}
          <div className="w-4.5 h-2.5 border border-[#113121]/60 rounded p-px flex items-center">
            <span className="h-full w-4 bg-[#113121] rounded-xs" />
          </div>
        </div>
      </div>

      {/* Primary Mobile App Viewport */}
      <div className="flex-1 relative overflow-hidden bg-[#FAF7F2]">
        {renderActiveScreen()}
      </div>

      {/* Deep dark forest green bottom nav menu styled perfectly like image */}
      <div className="absolute bottom-0 inset-x-0 bg-[#113121] pt-3.5 pb-6 px-4 flex items-center justify-between border-t border-emerald-900/10 rounded-t-[32px] shadow-[0_-8px_24px_rgba(11,35,23,0.15)] z-40 select-none">
        
        {/* Nav item 1: Home */}
        <button
          onClick={() => navigate("home")}
          className={`flex flex-col items-center flex-1 transition-all ${
            activeScreen === "home" ? "text-[#FAF7F2] font-black scale-105" : "text-white/45 hover:text-white/80"
          }`}
        >
          <Home className="w-[18px] h-[18px]" />
          <span className="text-[8px] tracking-tight mt-1 font-sans">Home</span>
        </button>

        {/* Nav item 2: Learn */}
        <button
          onClick={() => navigate("learn")}
          className={`flex flex-col items-center flex-1 transition-all ${
            activeScreen === "learn" ? "text-[#FAF7F2] font-black scale-105" : "text-white/45 hover:text-white/80"
          }`}
        >
          <BookOpen className="w-[18px] h-[18px]" />
          <span className="text-[8px] tracking-tight mt-1 font-sans">Learn</span>
        </button>

        {/* Floating Custom Center Action Button (Circular protruding leaf) */}
        <div className="flex-1 flex justify-center relative -mt-6 -mx-1.5">
          <button
            onClick={() => navigate("conditions")}
            title="View health remedy directory"
            className={`w-[48px] h-[48px] rounded-full flex items-center justify-center transition-all duration-350 shadow-md transform border border-emerald-950 ring-4 ring-[#113121]/20 ${
              activeScreen === "conditions" 
                ? "bg-[#836C45] text-white scale-110" 
                : "bg-emerald-50 text-[#113121] hover:bg-emerald-100 hover:scale-105"
            }`}
          >
            <Leaf className="w-5 h-5 stroke-[2]" />
          </button>
        </div>

        {/* Nav item 4: Ask Expert */}
        <button
          onClick={() => navigate("ask-expert")}
          className={`flex flex-col items-center flex-1 transition-all ${
            activeScreen === "ask-expert" ? "text-[#FAF7F2] font-black scale-105" : "text-white/45 hover:text-white/80"
          }`}
        >
          <MessageSquare className="w-[18px] h-[18px]" />
          <span className="text-[8px] tracking-tight mt-1 font-sans">Ask Expert</span>
        </button>

        {/* Nav item 5: Profile */}
        <button
          onClick={() => navigate("profile")}
          className={`flex flex-col items-center flex-1 transition-all ${
            activeScreen === "profile" ? "text-[#FAF7F2] font-black scale-105" : "text-white/45 hover:text-white/80"
          }`}
        >
          <User className="w-[18px] h-[18px]" />
          <span className="text-[8px] tracking-tight mt-1 font-sans">Profile</span>
        </button>
      </div>
    </div>
  );
}
