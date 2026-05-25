import PublicFooter from "./public/PublicFooter";
import PublicHeader from "./public/PublicHeader";

export default function PublicLayout({ children }) {
  return (
    <div className="min-h-screen flex flex-col bg-white text-slate-900">
      <PublicHeader />
      <main className="flex-1">{children}</main>
      <PublicFooter />
    </div>
  );
}
