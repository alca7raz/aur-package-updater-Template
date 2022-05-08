## AUR Package Updater

An automatic bot that helps check updates from upstream and push them to AUR.

### Usage

1. Push your first commit to AUR repository manually

2. Rename PKGBUILD to `PKGBUILD.template` and .SRCINFO to `SRCINFO.template`

3. Edit these templates

   - Replace the value of pkgver with `%%pkgver%%` placeholder in both PKGBUILD and SRCINFO

     ```
     # PKGBUILD
     pkgver=%%pkgver%%
     # SRCINFO
     	pkgver = %%pkgver%%
     ```

   - Replace the value of sha256sums with `%%sha256sum%%` placeholder in both PKGBUILD and SRCINFO

     If you have other patches, leave them still.

     ```
     # PKGBUILD
     sha256sums=('%%sha256sum%%')
     # SRCINFO
     	sha256sums = %%sha256sum%%
     ```

   - If the source link contains `$pkgver`, replace it in SRCINFO as well

4. Modify the update script as the comments

5. Set necessary environment variables to secrets

   - Set your AUR username and email as `AUR_NAME` and `AUR_EMAIL`

   - Encode your AUR private key with Base64. e.g.

     ```bash
     base64 aur_privkey
     ```

     Copy the result and set it as `AUR_PRIVKEY_BASE64`

- When you have pushed the modification, the workflow will start automatically. Check the result on the Actions page later.

