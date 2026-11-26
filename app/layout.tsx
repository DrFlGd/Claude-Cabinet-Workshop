import type { Metadata } from "next";
import "./globals.css";
import "./products/products.css";

export const metadata: Metadata = {
  title: "Cabinet Workshop",
  description: "Configure cabinets, explore layouts, and export your OpenSCAD project.",
  other: {
    "codex-preview": "development",
  },
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
