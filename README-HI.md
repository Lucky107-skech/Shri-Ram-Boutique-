# Shri Ram Boutique — Production setup (Hindi)

Yeh project Vercel par free `*.vercel.app` subdomain ke saath deploy karne aur Supabase par auth/database chalane ke liye bana hai. Razorpay abhi integrate nahi hai. Online payments enable karne se pehle verified payment backend/webhook add karna hoga.

## Store details included
- Brand: Shri Ram Boutique
- Phone / WhatsApp: +91 86997 55786
- Address: Kamal Vihar, Jalandhar City, Punjab, India
- Instagram: @Aditya.pal2311
- Design: premium maroon, cream, gold

## Free services you need
1. **GitHub** — project code repository.
2. **Supabase** — customer accounts and PostgreSQL database.
3. **Vercel** — frontend hosting and free `your-project.vercel.app` address.

Free-plan limits and provider policies can change. You must create and authorize these accounts yourself. Do not send anyone your password or secret keys.

## Step 1 — Create Supabase database
1. Open https://supabase.com and create a project.
2. Choose a project name such as `shri-ram-boutique`, create a strong database password, and save it privately.
3. Wait for the database to finish provisioning.
4. In the project dashboard, open **SQL Editor → New query**.
5. Open `supabase/schema.sql` from this project, copy all its contents into SQL Editor, then click **Run**.
6. Open **Project Settings → API** (or **Data API**, depending on the dashboard). Copy the Project URL and the publishable/anon key. Only use the public publishable/anon key in the browser app. **Never use a `service_role` or secret key in Vercel's `VITE_` variables or in frontend code.**

## Step 2 — Create your owner account and grant admin role
1. First deploy the website (Step 3 and 4), then open it and sign up with the email address you want to use as shop owner.
2. In Supabase, open **SQL Editor → New query** and run the following after replacing the email with your exact sign-up email:

```sql
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = lower('YOUR-OWNER-EMAIL@example.com');
```

3. Run it only for your own owner email. Do not expose admin access to customers.
4. Sign out and sign back in on the website. You should now see the admin/dashboard icon.

## Step 3 — Put the project on GitHub
1. Sign up/log in at https://github.com.
2. Create a **private** repository named `shri-ram-boutique` (recommended while configuring).
3. Upload the project files and folders from this ZIP to the repository. Upload the *contents* of the extracted folder, including `src`, `supabase`, `package.json`, `index.html`, and `vercel.json`. Do not upload `.env` files, passwords, or secret keys.
4. Make sure `package.json` is at the repository root, not nested inside another folder.

## Step 4 — Deploy on Vercel free subdomain
1. Open https://vercel.com and sign in using GitHub.
2. Choose **Add New → Project**, import your `shri-ram-boutique` repository.
3. Framework should be detected as **Vite**. Build command: `npm run build`; output directory: `dist`.
4. Before deploying, add these **Environment Variables**:
   - `VITE_SUPABASE_URL` = your Supabase Project URL
   - `VITE_SUPABASE_ANON_KEY` = your Supabase publishable/anon key
5. Click **Deploy**. Vercel will assign a URL similar to `https://shri-ram-boutique.vercel.app` (the exact available name may differ).
6. Open the assigned URL. For future code updates, push changes to GitHub and Vercel will redeploy.

## Step 5 — Set Supabase authentication URL
In Supabase dashboard, open **Authentication → URL Configuration**:
- Site URL: your actual Vercel URL, for example `https://YOUR-PROJECT.vercel.app`
- Add that same URL under Redirect URLs if required.
Save changes. Test sign-up, email confirmation (if enabled), sign-in, and sign-out.

## Step 6 — Add real products and test orders
- Sign up with your owner email, run the SQL admin-role command, then sign in again.
- Open the admin icon in the site header.
- Add products with actual prices, stock quantities, image URLs, category, and description.
- Use image URLs that you own or are allowed to use. Sample product photos are placeholders, not a guarantee that the depicted items are your actual stock.
- Test with a customer account: sign up, add products to bag, enter delivery details, and place an order.
- In admin, review orders, update order status, and check monthly order value.

## Important production notes
- This version saves accounts, products, and order requests to Supabase when configured. The sample catalogue appears before configuration; once the database has products, the live catalogue is loaded from it.
- Orders are `pending` and `pay_on_confirmation`; **no online payment is taken**. Confirm orders and payment/delivery details with the customer separately until a secure payment flow is implemented.
- Sales figures shown are recorded order value, not verified bank receipts. Exclude cancelled orders from the headline total.
- Stock is displayed and checked in the UI, but this starter does not yet implement atomic stock decrement/reservation. For high-volume sales, add a trusted server-side checkout function.
- Admin role is granted manually in the database. Customers cannot set their own role through the public signup form; row-level security policies protect product/order data.
- Do not collect unnecessary customer information, do not share customer/order records, and keep owner email secure.
- Free plans may have sleep/usage limits, and free subdomains can be changed if provider policies or project naming constraints require it.
- Before public launch, add your business policies: shipping, returns/refunds, privacy policy, terms, and support hours.
- Razorpay is intentionally omitted. When added, create orders server-side, verify signatures on the server, and validate payment webhooks before marking an order paid. Never put Razorpay secret keys in frontend code.
