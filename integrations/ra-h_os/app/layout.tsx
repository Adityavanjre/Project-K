import './globals.css';
import { AuthProvider } from '@/context/AuthContext';
import AutoUpdateManager from '@/components/system/AutoUpdateManager';
import ExternalNavigationManager from '@/components/system/ExternalNavigationManager';

export const metadata = {
  title: 'RA-H - Knowledge Management System',
  description: 'A simplified, open-source knowledge management system',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" suppressHydrationWarning>
      <head>
        <script
          dangerouslySetInnerHTML={{
            __html: `
              (function() {
                try {
                  var rawTheme = localStorage.getItem('ui.theme');
                  var theme = 'dark';
                  if (rawTheme !== null) {
                    try {
                      theme = JSON.parse(rawTheme) === 'light' ? 'light' : 'dark';
                    } catch (parseError) {
                      theme = rawTheme === 'light' ? 'light' : 'dark';
                    }
                  }
                  document.documentElement.setAttribute('data-theme', theme);
                } catch (error) {
                  document.documentElement.setAttribute('data-theme', 'dark');
                }
              })();
            `,
          }}
        />
      </head>
      <body>
        <AuthProvider>
          <AutoUpdateManager />
          <ExternalNavigationManager />
          {children}
        </AuthProvider>
      </body>
    </html>
  );
}
