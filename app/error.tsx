'use client';
export default function ErrorPage({reset}:{reset:()=>void}){return <main className="empty"><h1>A little interruption.</h1><p>We couldn’t load this page. Please try again.</p><button className="button dark" onClick={reset}>Try again</button></main>}
