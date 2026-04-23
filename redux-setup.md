# Redux in Next.js — Project Reference

A practical guide for wiring Redux Toolkit into your Next.js app alongside the existing `/api/products` route. Keep this open while building.

---

## 1. The mental model in 60 seconds

**State** = what the app remembers between moments. Modal open? Who's logged in? What's in the cart? Something has to hold that.

**Redux** = a single shared container (the _store_) that any component can read from or request changes to. Updates are strict:

1. Components **dispatch** an _action_ (a plain object: "user clicked buy").
2. A **reducer** takes the current state and the action, returns the next state.
3. The store saves it. Subscribed components re-render.

Unidirectional, predictable, replayable. Redux Toolkit (RTK) is the official wrapper that strips out the 2017-era boilerplate.

**Rule of thumb**: reach for `useState` first, Context for rarely-changing values (theme, auth), Redux when multiple components share interactive state and you want structure + DevTools.

---

## 2. Install

```bash
npm install @reduxjs/toolkit react-redux
```

That's it. TypeScript types ship with both packages.

---

## 3. Project structure

```
app/
├── api/
│   └── products/
│       └── route.ts          ← your existing API
├── layout.tsx                ← wire provider here
├── page.tsx
└── StoreProvider.tsx         ← client boundary for Redux
lib/
├── store.ts                  ← store factory + types
├── hooks.ts                  ← typed hooks
└── features/
    └── products/
        └── productsSlice.ts  ← state, actions, reducer for products
```

Two directories: `app/` for routes and the provider (Next.js convention), `lib/` for everything Redux-related (framework-agnostic, no Next.js concepts leak in).

---

## 4. Step one — the store (as a factory)

**Critical Next.js nuance**: do NOT export a singleton store. Server processes serve many users; a shared store would leak state between requests. Export a **factory** instead.

```typescript
// lib/store.ts
import { configureStore } from "@reduxjs/toolkit";
import productsReducer from "./features/products/productsSlice";

export const makeStore = () => {
  return configureStore({
    reducer: {
      products: productsReducer,
      // future slices go here: cart, user, filters...
    },
  });
};

// Types inferred from the store itself — stay in sync automatically
export type AppStore = ReturnType<typeof makeStore>;
export type RootState = ReturnType<AppStore["getState"]>;
export type AppDispatch = AppStore["dispatch"];
```

---

## 5. Step two — typed hooks (do this once, thank yourself later)

Instead of importing `useSelector` / `useDispatch` everywhere and retyping them, make pre-typed versions.

```typescript
// lib/hooks.ts
import { useDispatch, useSelector, useStore } from "react-redux";
import type { AppDispatch, RootState, AppStore } from "./store";

export const useAppDispatch = useDispatch.withTypes<AppDispatch>();
export const useAppSelector = useSelector.withTypes<RootState>();
export const useAppStore = useStore.withTypes<AppStore>();
```

Now in components you just write `const dispatch = useAppDispatch()` and everything's typed correctly.

---

## 6. Step three — the provider (the only client component involved in setup)

```tsx
// app/StoreProvider.tsx
"use client";
import { useRef } from "react";
import { Provider } from "react-redux";
import { makeStore, type AppStore } from "@/lib/store";

export default function StoreProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const storeRef = useRef<AppStore | null>(null);

  // Create the store exactly once per client render
  if (!storeRef.current) {
    storeRef.current = makeStore();
  }

  return <Provider store={storeRef.current}>{children}</Provider>;
}
```

The `useRef` pattern ensures one store per browser tab, not one per render. Without it, every re-render would create a new store and wipe your state.

---

## 7. Step four — wire the provider into the root layout

```tsx
// app/layout.tsx
import StoreProvider from "./StoreProvider";

// Note: no 'use client' here. Layout stays a Server Component.
// Only StoreProvider opts into the client boundary.

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <StoreProvider>{children}</StoreProvider>
      </body>
    </html>
  );
}
```

Keep the client boundary as narrow as possible. The layout itself can still run on the server; only the provider and components that genuinely need hooks go into `'use client'` land.

---

## 8. Step five — the products slice

Two ways to handle API data. Pick one based on the section below titled "Which approach?"

### 8a. Option A — `createAsyncThunk` (manual, explicit, more code)

```typescript
// lib/features/products/productsSlice.ts
import {
  createSlice,
  createAsyncThunk,
  type PayloadAction,
} from "@reduxjs/toolkit";

// Adjust this type to match what your /api/products actually returns
export type Product = {
  id: number;
  name: string;
  price: number;
  description?: string;
};

type Status = "idle" | "loading" | "succeeded" | "failed";

type ProductsState = {
  items: Product[];
  status: Status;
  error: string | null;
  selectedId: number | null;
};

const initialState: ProductsState = {
  items: [],
  status: "idle",
  error: null,
  selectedId: null,
};

// ── Async action: calls your existing /api/products route
export const fetchProducts = createAsyncThunk<Product[]>(
  "products/fetch",
  async () => {
    const res = await fetch("/api/products");
    if (!res.ok) throw new Error("Failed to load products");
    return res.json();
  },
);

const productsSlice = createSlice({
  name: "products",
  initialState,
  reducers: {
    // Synchronous actions — UI state that doesn't need the server
    productSelected(state, action: PayloadAction<number>) {
      state.selectedId = action.payload;
    },
    productDeselected(state) {
      state.selectedId = null;
    },
  },
  extraReducers: (builder) => {
    builder
      .addCase(fetchProducts.pending, (state) => {
        state.status = "loading";
        state.error = null;
      })
      .addCase(
        fetchProducts.fulfilled,
        (state, action: PayloadAction<Product[]>) => {
          state.status = "succeeded";
          state.items = action.payload;
        },
      )
      .addCase(fetchProducts.rejected, (state, action) => {
        state.status = "failed";
        state.error = action.error.message ?? "Unknown error";
      });
  },
});

export const { productSelected, productDeselected } = productsSlice.actions;
export default productsSlice.reducer;
```

Notes on the reducer:

- You can write `state.items = action.payload` ("mutation") inside a slice reducer. Immer converts it to an immutable update under the hood.
- `extraReducers` handles actions defined elsewhere (here, the three auto-generated thunk actions).
- Don't mix mutation and `return` in the same reducer — pick one style.

### 8b. Option B — RTK Query (caching, deduplication, refetching for free)

This replaces the entire thunk + status tracking above with ~15 lines. Prefer this for pure API data.

```typescript
// lib/features/products/productsApi.ts
import { createApi, fetchBaseQuery } from "@reduxjs/toolkit/query/react";

export type Product = {
  id: number;
  name: string;
  price: number;
  description?: string;
};

export const productsApi = createApi({
  reducerPath: "productsApi",
  baseQuery: fetchBaseQuery({ baseUrl: "/api" }),
  tagTypes: ["Products"],
  endpoints: (builder) => ({
    getProducts: builder.query<Product[], void>({
      query: () => "products",
      providesTags: ["Products"],
    }),
    getProduct: builder.query<Product, number>({
      query: (id) => `products/${id}`,
      providesTags: (_result, _error, id) => [{ type: "Products", id }],
    }),
    addProduct: builder.mutation<Product, Partial<Product>>({
      query: (product) => ({
        url: "products",
        method: "POST",
        body: product,
      }),
      invalidatesTags: ["Products"],
    }),
  }),
});

// Auto-generated hooks — one per endpoint
export const {
  useGetProductsQuery,
  useGetProductQuery,
  useAddProductMutation,
} = productsApi;
```

If you use RTK Query, register its reducer and middleware in the store:

```typescript
// lib/store.ts  (RTK Query version)
import { configureStore } from "@reduxjs/toolkit";
import { productsApi } from "./features/products/productsApi";

export const makeStore = () => {
  return configureStore({
    reducer: {
      [productsApi.reducerPath]: productsApi.reducer,
    },
    middleware: (getDefaultMiddleware) =>
      getDefaultMiddleware().concat(productsApi.middleware),
  });
};
```

You can run **both** thunk slices and RTK Query slices in the same store — they don't conflict.

---

## 9. Using it in a component

### With the thunk approach

```tsx
// app/products/ProductsList.tsx
"use client";
import { useEffect } from "react";
import { useAppDispatch, useAppSelector } from "@/lib/hooks";
import {
  fetchProducts,
  productSelected,
} from "@/lib/features/products/productsSlice";

export default function ProductsList() {
  const dispatch = useAppDispatch();
  const { items, status, error, selectedId } = useAppSelector(
    (s) => s.products,
  );

  useEffect(() => {
    if (status === "idle") {
      dispatch(fetchProducts());
    }
  }, [status, dispatch]);

  if (status === "loading") return <p>Loading…</p>;
  if (status === "failed") return <p>Error: {error}</p>;

  return (
    <ul>
      {items.map((product) => (
        <li
          key={product.id}
          onClick={() => dispatch(productSelected(product.id))}
          className={product.id === selectedId ? "selected" : ""}
        >
          <h3>{product.name}</h3>
          <p>€{product.price.toFixed(2)}</p>
        </li>
      ))}
    </ul>
  );
}
```

### With RTK Query (dramatically less code)

```tsx
// app/products/ProductsList.tsx
"use client";
import { useGetProductsQuery } from "@/lib/features/products/productsApi";

export default function ProductsList() {
  const { data: products, isLoading, isError, error } = useGetProductsQuery();

  if (isLoading) return <p>Loading…</p>;
  if (isError) return <p>Error loading products</p>;

  return (
    <ul>
      {products?.map((product) => (
        <li key={product.id}>
          <h3>{product.name}</h3>
          <p>€{product.price.toFixed(2)}</p>
        </li>
      ))}
    </ul>
  );
}
```

Caching, deduplication, and refetch are handled automatically. Mutations (adding, deleting) can invalidate tags to trigger refetches.

---

## 10. Which approach? Thunk vs RTK Query

| Use **thunk** when                                                                                              | Use **RTK Query** when                                                      |
| --------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| You have complex local state alongside the fetch (filters, selections, optimistic updates with intricate rules) | The data is server data, period. You fetch it, display it, maybe mutate it. |
| You want total control over when and how requests fire                                                          | You want caching + deduplication + auto-refetch handled for you             |
| Teaching students the Redux loop explicitly                                                                     | Building real features fast                                                 |

For your products app, **RTK Query is almost certainly the right call** for the list/detail/add flow. Reserve thunks for things like "apply filters and sort client-side" or "manage cart with optimistic updates."

---

## 11. Selectors and memoisation

`useAppSelector` re-runs on _every_ store change. If your selector returns a new array/object each time, the component re-renders even when nothing relevant changed.

**The problem:**

```typescript
// ❌ filter() returns a new array every call — re-renders on every action
const cheapProducts = useAppSelector((s) =>
  s.products.items.filter((p) => p.price < 10),
);
```

**The fix — `createSelector`:**

```typescript
// lib/features/products/selectors.ts
import { createSelector } from "@reduxjs/toolkit";
import type { RootState } from "@/lib/store";

const selectAllProducts = (state: RootState) => state.products.items;

export const selectCheapProducts = createSelector(
  [selectAllProducts],
  (products) => products.filter((p) => p.price < 10),
);

// In the component:
// const cheap = useAppSelector(selectCheapProducts)
```

Only recomputes when `items` actually changes reference. Memoised, predictable, and cheap to use.

---

## 12. When NOT to use Redux

Next.js gives you server-side data fetching for free. **Do not put everything in Redux.**

- **Initial page data, static-ish lists**: fetch in a Server Component. Zero client-side JS for that data, faster first paint. Pass it down as props, or hydrate a Redux slice only if the client needs to mutate it.
- **Form inputs, modal open/closed, hover states, dropdown open**: `useState`. Not everything needs to be global.
- **Theme, current user, locale**: Context is fine. Low-frequency values.
- **Server data you never mutate on the client**: Server Components, or RTK Query, or libraries like TanStack Query. Don't hand-roll thunks for this.

Redux earns its keep for **interactive, cross-cutting, client-side state** — cart contents, applied filters, optimistic UI updates, multi-step wizards, selected items across views.

---

## 13. Pitfalls to avoid

1. **Singleton store in Next.js** — always use the `makeStore` factory + `useRef` pattern. A bare exported store leaks state between users during SSR.
2. **Forgetting `'use client'`** — any component using `useAppSelector` or `useAppDispatch` must be a Client Component. Server Components can't use hooks.
3. **Mixing mutation and return in reducers** — inside a slice, either write `state.x = y` OR `return { ...state, x: y }`. Both in the same reducer breaks Immer silently.
4. **Non-serialisable state** — don't store Dates, class instances, or functions in the store. Use ISO strings, plain objects, and IDs. It keeps DevTools and persistence working.
5. **Selectors that return new objects on every call** — wrap in `createSelector`, or return primitives.
6. **Overusing Redux** — if one component owns the state, `useState` is better. Redux is a shared whiteboard, not a default.

---

## 14. The API surface you'll actually use

| Function           | Purpose                                                      |
| ------------------ | ------------------------------------------------------------ |
| `configureStore`   | Creates the store, wires DevTools + middleware automatically |
| `createSlice`      | Generates reducer + action creators for one feature          |
| `createAsyncThunk` | Standardised async action with pending/fulfilled/rejected    |
| `createSelector`   | Memoised selector — derived state                            |
| `createApi`        | Full data-fetching layer (RTK Query)                         |
| `useAppSelector`   | Read from store (your typed version)                         |
| `useAppDispatch`   | Get dispatch function (your typed version)                   |
| `<Provider>`       | Make the store available to the component tree               |

Ninety percent of your Redux code will touch only these.

---

## 15. Quick setup checklist

For this project, in order:

- [ ] `npm install @reduxjs/toolkit react-redux`
- [ ] Create `lib/store.ts` with the `makeStore` factory
- [ ] Create `lib/hooks.ts` with typed `useAppSelector` / `useAppDispatch`
- [ ] Create `app/StoreProvider.tsx` with the `useRef` pattern
- [ ] Wrap `{children}` in `<StoreProvider>` inside `app/layout.tsx`
- [ ] Create `lib/features/products/` and decide: thunk or RTK Query
- [ ] Register the reducer (or API) in the store
- [ ] Build a `'use client'` component that uses the hooks
- [ ] Install Redux DevTools browser extension — `configureStore` wires it automatically

Once this is live, adding more features (cart, filters, auth) is just new slices registered in the same store.
