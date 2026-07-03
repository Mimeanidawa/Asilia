import React, { useState, useRef, useEffect } from "react";
import { useApp } from "../context/AppContext";
import { Send, Image, MessageSquare, Sparkles, RefreshCw, X } from "lucide-react";

const ATTACHMENT_PRESETS = [
  {
    name: "Neem Leaf Plant",
    url: "https://images.unsplash.com/photo-1564594736624-def7a10ab047?auto=format&fit=crop&q=80&w=150",
    // Clean mock base64 representing a green leaf or simply use a mock string
    base64Url: "https://images.unsplash.com/photo-1564594736624-def7a10ab047?auto=format&fit=crop&q=80&w=150"
  },
  {
    name: "Stomach Plant / Aloe Gel",
    url: "https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=150",
    base64Url: "https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?auto=format&fit=crop&q=80&w=150"
  },
  {
    name: "Ginger Root Slice",
    url: "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=150",
    base64Url: "https://images.unsplash.com/photo-1615485290382-441e4d049cb5?auto=format&fit=crop&q=80&w=150"
  }
];

export default function AskExpertScreen() {
  const { chatMessages, sendChatMessage, isChatLoading, clearChat } = useApp();
  const [inputText, setInputText] = useState("");
  const [attachedImage, setAttachedImage] = useState<string | null>(null);
  const [showAttachmentMenu, setShowAttachmentMenu] = useState(false);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [chatMessages, isChatLoading]);

  const handleSend = async () => {
    if (!inputText.trim() && !attachedImage) return;
    const textToSend = inputText;
    const imgToSend = attachedImage;
    
    setInputText("");
    setAttachedImage(null);
    setShowAttachmentMenu(false);

    await sendChatMessage(textToSend, imgToSend || undefined);
  };

  const handlePromptClick = (questionText: string) => {
    setInputText(questionText);
  };

  const selectPresetImage = (url: string) => {
    setAttachedImage(url);
    setShowAttachmentMenu(false);
  };

  return (
    <div className="flex flex-col h-full bg-[#FAF7F2] text-[#113121] select-none">
      {/* Top Header */}
      <div className="flex items-center justify-between px-5 pt-4 pb-3 bg-white border-b border-emerald-800/[0.03] shrink-0">
        <div className="flex items-center space-x-2">
          <MessageSquare className="w-5 h-5 text-emerald-800" />
          <span className="text-sm font-black font-sans uppercase tracking-tight">Ask an Expert</span>
        </div>
        <button
          onClick={clearChat}
          title="Reset clinic consultation"
          className="p-1 text-gray-400 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
        >
          <RefreshCw className="w-4 h-4" />
        </button>
      </div>

      {/* Expert Portrait Profile Card */}
      <div className="px-5 py-3.5 bg-gradient-to-b from-white to-[#FAF7F2] shrink-0 border-b border-emerald-800/[0.03]">
        <div className="flex items-center space-x-4 p-3 bg-white border border-emerald-800/[0.04] rounded-2xl shadow-sm">
          <div className="relative shrink-0">
            {/* Dr. Mussa Hassan profile picture matching the green background doctor portrait */}
            <img
              src="https://images.unsplash.com/photo-1537368910025-700350fe46c7?auto=format&fit=crop&q=80&w=200"
              alt="Dr. Mussa Hassan"
              className="w-14 h-14 rounded-full object-cover border-2 border-emerald-800/20"
            />
            <span className="absolute bottom-0.5 right-0.5 w-3.5 h-3.5 bg-emerald-500 border-2 border-white rounded-full animate-pulse" />
          </div>
          <div className="min-w-0 flex-1">
            <h4 className="text-base font-black tracking-tight text-[#113121]">Dr. Mussa Hassan</h4>
            <p className="text-[10px] text-gray-500 font-bold leading-tight uppercase tracking-wider">
              Herbal Medicine Specialist
            </p>
            <div className="flex items-center space-x-1.5 mt-1">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              <span className="text-[9px] text-emerald-700 font-extrabold uppercase">Online</span>
            </div>
          </div>
        </div>
        <p className="text-[10px] text-gray-500 font-sans mt-2 ml-1 leading-normal">
          How can we help you today? Send any symptoms or queries below. Dr. Hassan responds instantly.
        </p>
      </div>

      {/* Chat Messages Log Area */}
      <div 
        ref={scrollRef}
        className="flex-1 overflow-y-auto px-5 py-3 space-y-4"
      >
        {chatMessages.map((msg) => (
          <div
            key={msg.id}
            className={`flex flex-col ${msg.role === "user" ? "items-end" : "items-start"}`}
          >
            {msg.role === "user" ? (
              <div className="max-w-[85%] bg-[#113121] text-white p-3 rounded-2xl rounded-tr-sm shadow-sm">
                {msg.image && (
                  <img
                    src={msg.image}
                    alt="Attached herb"
                    className="w-32 h-24 object-cover rounded-lg mb-2 border border-white/20"
                  />
                )}
                <p className="text-xs font-sans leading-relaxed">{msg.content}</p>
              </div>
            ) : (
              <div className="max-w-[85%] bg-white border border-emerald-800/[0.03] text-gray-700 p-3.5 rounded-2xl rounded-tl-sm shadow-sm space-y-2">
                <div className="text-[10px] font-bold text-emerald-800 flex items-center space-x-1">
                  <Sparkles className="w-3 h-3 text-[#836C45]" />
                  <span>Dr. Hassan</span>
                </div>
                <div className="text-xs font-sans leading-relaxed whitespace-pre-wrap">{msg.content}</div>
              </div>
            )}
          </div>
        ))}

        {isChatLoading && (
          <div className="flex items-center space-x-2 text-xs text-gray-400 font-medium pl-1 italic">
            <span className="w-2 h-2 bg-emerald-700 rounded-full animate-bounce" />
            <span className="w-2 h-2 bg-emerald-700 rounded-full animate-bounce [animation-delay:0.2s]" />
            <span className="w-2 h-2 bg-emerald-700 rounded-full animate-bounce [animation-delay:0.4s]" />
            <span>Dr. Hassan is preparing a herbal advice...</span>
          </div>
        )}
      </div>

      {/* Attachment Presets Drawer overlay */}
      {showAttachmentMenu && (
        <div className="p-3 bg-white border-t border-emerald-800/10 shrink-0 select-none animate-in slide-in-from-bottom-5 duration-200">
          <div className="flex justify-between items-center mb-2 px-1">
            <h5 className="text-[10px] font-black uppercase text-gray-400 tracking-wider">Attach Plant Photo</h5>
            <button onClick={() => setShowAttachmentMenu(false)} className="text-gray-400 hover:text-red-700">
              <X className="w-4 h-4" />
            </button>
          </div>
          <div className="grid grid-cols-3 gap-2">
            {ATTACHMENT_PRESETS.map((preset, idx) => (
              <button
                key={idx}
                type="button"
                onClick={() => selectPresetImage(preset.base64Url)}
                className="flex flex-col items-center bg-emerald-50/50 p-1.5 rounded-xl border border-emerald-800/10 hover:border-emerald-800 transition-colors text-center"
              >
                <img src={preset.url} alt={preset.name} className="w-full h-10 object-cover rounded-lg mb-1" />
                <span className="text-[8px] font-extrabold text-[#113121] leading-none line-clamp-1">{preset.name}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* Suggested Quick Prompt Chips (Clickable accordions) */}
      <div className="px-5 py-2.5 bg-white border-t border-emerald-800/[0.03] space-y-1.5 shrink-0">
        <h5 className="text-[9px] font-black uppercase tracking-wider text-gray-400">Popular Questions</h5>
        <div className="grid grid-cols-1 gap-1.5">
          {[
            "What herbs help with high blood pressure?",
            "How can I boost my immunity naturally?"
          ].map((prompt, idx) => (
            <button
              key={idx}
              onClick={() => handlePromptClick(prompt)}
              className="text-left text-[11px] font-black py-2 px-3 bg-[#FAF7F2] border border-emerald-800/[0.02] hover:bg-emerald-50 rounded-xl flex items-center justify-between text-[#113121]"
            >
              <span>{prompt}</span>
              <Sparkles className="w-3.5 h-3.5 text-[#836C45]/80 shrink-0 ml-2" />
            </button>
          ))}
        </div>
      </div>

      {/* Input Composer Panel */}
      <div className="p-3 bg-white border-t border-emerald-800/[0.04] flex items-center space-x-2 shrink-0 pb-16">
        <button
          type="button"
          onClick={() => setShowAttachmentMenu(!showAttachmentMenu)}
          className={`p-2.5 rounded-xl transition-all ${
            attachedImage || showAttachmentMenu
              ? "bg-emerald-100 text-emerald-900"
              : "bg-emerald-50/50 hover:bg-emerald-100 text-[#113121]"
          }`}
        >
          <Image className="w-5 h-5" />
        </button>

        <div className="relative flex-1">
          <input
            type="text"
            placeholder={attachedImage ? "Image attached. Describe query..." : "Type your question here..."}
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && handleSend()}
            className="w-full bg-emerald-50/30 border border-emerald-800/10 rounded-xl py-3.5 pl-4 pr-10 text-xs font-semibold text-[#113121] placeholder-emerald-800/40 focus:outline-none focus:ring-1 focus:ring-[#113121] focus:bg-white transition-all shadow-inner"
          />

          {attachedImage && (
            <div className="absolute right-2 top-1/2 -translate-y-1/2 w-8 h-8 rounded-lg overflow-hidden border border-[#113121]/10">
              <img src={attachedImage} alt="Thumbnail preview" className="w-full h-full object-cover" />
              <button 
                onClick={() => setAttachedImage(null)}
                className="absolute inset-0 bg-black/60 text-white flex items-center justify-center opacity-0 hover:opacity-100 transition-opacity text-[8px] font-bold"
              >
                Clear
              </button>
            </div>
          )}
        </div>

        <button
          onClick={handleSend}
          className="p-3 bg-[#113121] hover:bg-emerald-900 text-white rounded-xl shadow-sm transition-colors"
        >
          <Send className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}
