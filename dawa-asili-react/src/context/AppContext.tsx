import React, { createContext, useContext, useState, useEffect } from "react";

export type ScreenType = "home" | "herb-details" | "ask-expert" | "learn" | "conditions" | "profile";

export interface ChatMessage {
  id: string;
  role: "user" | "model";
  content: string;
  image?: string; // base64
}

export interface Reminder {
  id: string;
  title: string;
  time: string;
  herbId: string;
  active: boolean;
}

export interface SavedQuestion {
  id: string;
  query: string;
  answer: string;
  timestamp: string;
}

interface AppContextType {
  activeScreen: ScreenType;
  screenHistory: ScreenType[];
  selectedHerbId: string | null;
  selectedConditionId: string | null;
  favorites: string[];
  chatMessages: ChatMessage[];
  reminders: Reminder[];
  questions: SavedQuestion[];
  isChatLoading: boolean;
  
  navigate: (screen: ScreenType, payload?: { herbId?: string; conditionId?: string }) => void;
  goBack: () => void;
  toggleFavorite: (herbId: string) => void;
  isFavorite: (herbId: string) => boolean;
  addReminder: (title: string, time: string, herbId: string) => void;
  toggleReminder: (id: string) => void;
  deleteReminder: (id: string) => void;
  sendChatMessage: (content: string, imageBase64?: string) => Promise<void>;
  clearChat: () => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [activeScreen, setActiveScreen] = useState<ScreenType>("home");
  const [screenHistory, setScreenHistory] = useState<ScreenType[]>(["home"]);
  const [selectedHerbId, setSelectedHerbId] = useState<string | null>("neem");
  const [selectedConditionId, setSelectedConditionId] = useState<string | null>(null);
  
  // Persistence using localStorage handles dynamic persistence elegantly
  const [favorites, setFavorites] = useState<string[]>(() => {
    const saved = localStorage.getItem("da_favorites");
    return saved ? JSON.parse(saved) : ["neem", "aloe", "lemongrass"];
  });

  const [reminders, setReminders] = useState<Reminder[]>(() => {
    const saved = localStorage.getItem("da_reminders");
    return saved ? JSON.parse(saved) : [
      { id: "rem-1", title: "Drink warm Mwarobaini Leaf Tea", time: "08:00 AM", herbId: "neem", active: true },
      { id: "rem-2", title: "Take fresh Aloe Vera Stomach Gel", time: "01:00 PM", herbId: "aloe", active: false }
    ];
  });

  const [questions, setQuestions] = useState<SavedQuestion[]>(() => {
    const saved = localStorage.getItem("da_questions");
    return saved ? JSON.parse(saved) : [
      { id: "q-1", query: "What herbs help with high blood pressure?", answer: "Vitunguu Saumu (Garlic) acts as a powerful vasodilator. Traditional use suggests taking 1 raw crushed clove each morning with a little honey.", timestamp: "Yesterday" }
    ];
  });

  const [chatMessages, setChatMessages] = useState<ChatMessage[]>(() => {
    const saved = localStorage.getItem("da_chat");
    return saved ? JSON.parse(saved) : [
      { id: "welcome", role: "model", content: "Karibu! I am Dr. Mussa Hassan, your Dawa Asili consulting expert. Tell me, what symptoms are you experiencing or which herb would you like to investigate?" }
    ];
  });

  const [isChatLoading, setIsChatLoading] = useState(false);

  useEffect(() => {
    localStorage.setItem("da_favorites", JSON.stringify(favorites));
  }, [favorites]);

  useEffect(() => {
    localStorage.setItem("da_reminders", JSON.stringify(reminders));
  }, [reminders]);

  useEffect(() => {
    localStorage.setItem("da_questions", JSON.stringify(questions));
  }, [questions]);

  useEffect(() => {
    localStorage.setItem("da_chat", JSON.stringify(chatMessages));
  }, [chatMessages]);

  const navigate = (screen: ScreenType, payload?: { herbId?: string; conditionId?: string }) => {
    if (payload?.herbId) setSelectedHerbId(payload.herbId);
    if (payload?.conditionId) setSelectedConditionId(payload.conditionId);
    
    setActiveScreen(screen);
    setScreenHistory((prev) => [...prev, screen]);
  };

  const goBack = () => {
    if (screenHistory.length > 1) {
      const newHistory = [...screenHistory];
      newHistory.pop(); // remove current
      const prevScreen = newHistory[newHistory.length - 1];
      setScreenHistory(newHistory);
      setActiveScreen(prevScreen);
    } else {
      setActiveScreen("home");
    }
  };

  const toggleFavorite = (herbId: string) => {
    setFavorites((prev) =>
      prev.includes(herbId) ? prev.filter((id) => id !== herbId) : [...prev, herbId]
    );
  };

  const isFavorite = (herbId: string) => favorites.includes(herbId);

  const addReminder = (title: string, time: string, herbId: string) => {
    const newRem: Reminder = {
      id: "rem-" + Date.now(),
      title,
      time,
      herbId,
      active: true,
    };
    setReminders((prev) => [...prev, newRem]);
  };

  const toggleReminder = (id: string) => {
    setReminders((prev) =>
      prev.map((r) => (r.id === id ? { ...r, active: !r.active } : r))
    );
  };

  const deleteReminder = (id: string) => {
    setReminders((prev) => prev.filter((r) => r.id !== id));
  };

  const sendChatMessage = async (content: string, imageBase64?: string) => {
    if (!content.trim() && !imageBase64) return;

    const userMsg: ChatMessage = {
      id: "msg-" + Date.now(),
      role: "user",
      content: content,
      image: imageBase64,
    };

    setChatMessages((prev) => [...prev, userMsg]);
    setIsChatLoading(true);

    try {
      // Prepare previous messages for context
      const history = chatMessages
        .filter((m) => m.id !== "welcome")
        .slice(-6)
        .map((m) => ({
          role: m.role,
          content: m.content,
        }));

      const response = await fetch("/api/chat-expert", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: history,
          currentMessage: content,
          image: imageBase64 ? { base64: imageBase64.split(",")[1] || imageBase64, mimeType: "image/png" } : null,
        }),
      });

      const data = await response.json();
      
      const botMsg: ChatMessage = {
        id: "msg-" + (Date.now() + 1),
        role: "model",
        content: data.content,
      };

      setChatMessages((prev) => [...prev, botMsg]);

      // Save to saved questions history if it's a substantive question
      if (content.length > 15) {
        const isDuplicate = questions.some((q) => q.query.toLowerCase() === content.toLowerCase());
        if (!isDuplicate) {
          const newQ: SavedQuestion = {
            id: "q-" + Date.now(),
            query: content,
            answer: data.content,
            timestamp: "Just Now"
          };
          setQuestions((prev) => [newQ, ...prev]);
        }
      }
    } catch (err) {
      console.error("Failed to fetch response from Dr. Hassan:", err);
      // Fallback
      const botMsg: ChatMessage = {
        id: "msg-" + (Date.now() + 1),
        role: "model",
        content: "Habari! My roots run deep but my network is struggling. Please ensure you are connected to the online server, or check back shortly. Neem, Aloe Vera and Lemongrass remain your true companions!",
      };
      setChatMessages((prev) => [...prev, botMsg]);
    } finally {
      setIsChatLoading(false);
    }
  };

  const clearChat = () => {
    setChatMessages([
      { id: "welcome", role: "model", content: "Karibu! I am Dr. Mussa Hassan, your Dawa Asili consulting expert. Tell me, what symptoms are you experiencing or which herb would you like to investigate?" }
    ]);
  };

  return (
    <AppContext.Provider
      value={{
        activeScreen,
        screenHistory,
        selectedHerbId,
        selectedConditionId,
        favorites,
        chatMessages,
        reminders,
        questions,
        isChatLoading,
        navigate,
        goBack,
        toggleFavorite,
        isFavorite,
        addReminder,
        toggleReminder,
        deleteReminder,
        sendChatMessage,
        clearChat,
      }}
    >
      {children}
    </AppContext.Provider>
  );
}

export function useApp() {
  const context = useContext(AppContext);
  if (context === undefined) {
    throw new Error("useApp must be used within an AppProvider");
  }
  return context;
}
