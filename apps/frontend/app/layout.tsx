import './styles.css';

export const metadata = {
  title: 'Notes App',
  description: 'A minimal, realistic notes taking application with Next.js, NestJS, and PostgreSQL',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}



