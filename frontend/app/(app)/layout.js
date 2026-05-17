import AuthenticatedApp from "../../components/authenticated-app";

export default function AppLayout({ children }) {
  return <AuthenticatedApp>{children}</AuthenticatedApp>;
}
