import Image from "next/image";
import React from "react";
import {redirect} from "next/navigation";

export default function Home() {
    redirect('/trade')
  return (
    <main className="flex min-h-screen flex-col items-center justify-between p-24">
        <h1>Home</h1>
    </main>
  );
}
