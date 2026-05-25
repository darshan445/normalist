import AuthenticatedApp from "../../components/authenticated-app";
import Providers from "../providers";

export default function AppLayout({ children }) {
  return (
    <Providers>
      <AuthenticatedApp>{children}</AuthenticatedApp>
    </Providers>
  );
}
