import React from "react";
import { AppProvider } from "./context/AppContext";
import SidebarBranding from "./components/SidebarBranding";
import MobileDeviceFrame from "./components/MobileDeviceFrame";

export default function App() {
  return (
    <AppProvider>
      <div className="min-h-screen bg-[#FAF7F2] relative overflow-x-hidden flex items-center justify-center p-4 md:p-8 font-sans selection:bg-[#113121]/15 leading-relaxed">
        {/* Subtle Organic Background Details */}
        <div className="absolute top-0 right-0 w-[450px] h-[450px] bg-emerald-800/[0.03] rounded-full filter blur-[100px] pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-[600px] h-[600px] bg-amber-850/[0.03] rounded-full filter blur-[120px] pointer-events-none" />

        <div className="relative w-full max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-center gap-12 lg:gap-20">
          {/* Left panel: Desktop Editorial/Branding column matching the image */}
          <div className="w-full md:w-1/2 flex items-center justify-center md:items-start md:justify-start">
            <SidebarBranding />
          </div>

          {/* Right panel: Active High-fidelity Smart Mobile Emulator Frame */}
          <div className="w-full md:w-1/2 flex items-center justify-center shrink-0">
            <MobileDeviceFrame />
          </div>
        </div>
      </div>
    </AppProvider>
  );
}

