import PublicFooter from "./public/PublicFooter";
import PublicHeader from "./public/PublicHeader";

export default function PublicLayout({ children }) {
  return (
    <div className="public-site min-h-screen flex flex-col bg-white text-base text-slate-900 antialiased">
      <PublicHeader />
      <main className="flex-1">{children}</main>
      <PublicFooter />
    </div>
  );
}
