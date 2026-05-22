"use client";

import { useEffect } from "react";
import { openExternalUrl, shouldOpenExternally } from "@/utils/openExternalUrl";

export default function ExternalNavigationManager() {
  useEffect(() => {
    const handleDocumentClick = (event: MouseEvent) => {
      if (event.defaultPrevented || event.button !== 0) {
        return;
      }

      const target = event.target;
      if (!(target instanceof Element)) {
        return;
      }

      const anchor = target.closest("a[href]");
      if (!(anchor instanceof HTMLAnchorElement)) {
        return;
      }

      const rawHref = anchor.getAttribute("href");
      if (!rawHref || rawHref.startsWith("#") || anchor.hasAttribute("download")) {
        return;
      }

      if (!shouldOpenExternally(rawHref)) {
        return;
      }

      event.preventDefault();
      event.stopPropagation();

      void openExternalUrl(anchor.href || rawHref).catch((error) => {
        console.error("[external] document click open failed", error);
        window.alert(`Unable to open this link automatically.\n\n${anchor.href || rawHref}`);
      });
    };

    document.addEventListener("click", handleDocumentClick, true);
    return () => {
      document.removeEventListener("click", handleDocumentClick, true);
    };
  }, []);

  return null;
}
