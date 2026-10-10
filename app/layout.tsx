import type {Metadata} from 'next';import './globals.css';
export const metadata:Metadata={title:'Tawakal Mart — Considered style. Everyday living.',description:'Fashion, footwear, bags and beauty for your kind of everyday. Cash on delivery across Pakistan.',icons:{icon:'/favicon.svg'}};
export default function RootLayout({children}:{children:React.ReactNode}){return <html lang="en"><body>{children}</body></html>}
