(() => { const u = new URL(location.href); u.searchParams.set('build', 'e14142fb3391a6cdda7e'); if (u.href !== location.href) location.replace(u); else location.reload(); })();
