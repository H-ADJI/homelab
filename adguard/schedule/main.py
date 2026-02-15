import asyncio
import os

from adguardhome import AdGuardHome


async def main():
    """Show example how to get status of your AdGuard Home instance."""
    password = os.getenv("ADGUARD_PASSWORD")
    async with AdGuardHome(
        host="adguard-setup.hadji.org", port=443, tls=True, username="khalil", password=password
    ) as adguard:
        version = await adguard.version()
        print("AdGuard version:", version)

        active = await adguard.protection_enabled()
        active = "Yes" if active else "No"
        print("Protection enabled?", active)

        if not active:
            print("AdGuard Home protection disabled. Enabling...")
            await adguard.enable_protection()


if __name__ == "__main__":
    asyncio.run(main())
