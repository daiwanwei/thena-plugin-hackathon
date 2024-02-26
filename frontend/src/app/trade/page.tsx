'use client';
import React from "react";
import {PerpActionCard} from "@/components/PerpActionCard";
import UserPerpPositionList from "@/components/UserPerpPositionList";

export default function Page() {
  return (
    <main className="flex min-h-screen flex-col items-center gap-4 p-24">
        <PerpActionCard/>
        <UserPerpPositionList/>
    </main>
  );
}
