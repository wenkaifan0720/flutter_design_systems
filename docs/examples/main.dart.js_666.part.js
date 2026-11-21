(() => { const u = new URL(location.href); u.searchParams.set('build', '90dc030ee82f57a2779f'); if (u.href !== location.href) location.replace(u); else location.reload(); })();
