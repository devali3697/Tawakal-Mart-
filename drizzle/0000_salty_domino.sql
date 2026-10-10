CREATE TABLE `audit` (
	`id` text PRIMARY KEY NOT NULL,
	`actor` text NOT NULL,
	`action` text NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `coupons` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`data` text NOT NULL,
	`used` integer DEFAULT 0 NOT NULL,
	`max_uses` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `coupons_code_unique` ON `coupons` (`code`);--> statement-breakpoint
CREATE TABLE `order_items` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`variant_id` text NOT NULL,
	`quantity` integer NOT NULL,
	`price` integer NOT NULL,
	`data` text NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`variant_id`) REFERENCES `variants`(`id`) ON UPDATE no action ON DELETE no action,
	CONSTRAINT "positive_quantity" CHECK("order_items"."quantity" > 0)
);
--> statement-breakpoint
CREATE TABLE `orders` (
	`id` text PRIMARY KEY NOT NULL,
	`number` text NOT NULL,
	`idempotency` text NOT NULL,
	`fingerprint` text NOT NULL,
	`status` text DEFAULT 'Pending' NOT NULL,
	`phone` text NOT NULL,
	`customer` text NOT NULL,
	`subtotal` integer NOT NULL,
	`discount` integer NOT NULL,
	`shipping` integer NOT NULL,
	`total` integer NOT NULL,
	`coupon_id` text,
	`created_at` text NOT NULL,
	`sample` integer DEFAULT 0 NOT NULL,
	`released` integer DEFAULT 0 NOT NULL,
	`courier` text DEFAULT '' NOT NULL,
	`tracking` text DEFAULT '' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`collected` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `orders_number_unique` ON `orders` (`number`);--> statement-breakpoint
CREATE UNIQUE INDEX `orders_idempotency_unique` ON `orders` (`idempotency`);--> statement-breakpoint
CREATE TABLE `products` (
	`id` text PRIMARY KEY NOT NULL,
	`slug` text NOT NULL,
	`data` text NOT NULL,
	`status` text NOT NULL,
	`sample` integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `products_slug_unique` ON `products` (`slug`);--> statement-breakpoint
CREATE TABLE `rate_limits` (
	`key` text PRIMARY KEY NOT NULL,
	`count` integer NOT NULL,
	`expires` integer NOT NULL
);
--> statement-breakpoint
CREATE TABLE `records` (
	`id` text PRIMARY KEY NOT NULL,
	`kind` text NOT NULL,
	`data` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `reviews` (
	`id` text PRIMARY KEY NOT NULL,
	`product_id` text NOT NULL,
	`name` text NOT NULL,
	`rating` integer NOT NULL,
	`body` text NOT NULL,
	`approved` integer DEFAULT 0 NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `subscribers` (
	`email` text PRIMARY KEY NOT NULL,
	`created_at` text NOT NULL
);
--> statement-breakpoint
CREATE TABLE `variants` (
	`id` text PRIMARY KEY NOT NULL,
	`product_id` text NOT NULL,
	`sku` text NOT NULL,
	`price` integer NOT NULL,
	`stock` integer NOT NULL,
	`data` text NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE cascade,
	CONSTRAINT "stock_nonnegative" CHECK("variants"."stock" >= 0),
	CONSTRAINT "price_nonnegative" CHECK("variants"."price" >= 0)
);
--> statement-breakpoint
CREATE UNIQUE INDEX `variants_sku_unique` ON `variants` (`sku`);--> statement-breakpoint
CREATE TRIGGER reserve_inventory BEFORE INSERT ON order_items BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM variants v JOIN products p ON p.id=v.product_id WHERE v.id=NEW.variant_id AND v.stock>=NEW.quantity AND v.price=NEW.price AND p.status='published' AND (p.sample=0 OR COALESCE((SELECT json_extract(data,'$.mode') FROM records WHERE id='settings'),'preview')='preview')) THEN RAISE(ABORT,'Inventory or price changed; please refresh your bag.') END;
 UPDATE variants SET stock=stock-NEW.quantity WHERE id=NEW.variant_id;
END;
--> statement-breakpoint
CREATE TRIGGER reserve_coupon BEFORE INSERT ON orders WHEN NEW.coupon_id IS NOT NULL BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM coupons WHERE id=NEW.coupon_id AND (max_uses=0 OR used<max_uses) AND json_extract(data,'$.active')=1 AND json_extract(data,'$.minimum')<=NEW.subtotal AND (json_extract(data,'$.expires')='' OR unixepoch(json_extract(data,'$.expires'))>=unixepoch()) AND (json_extract(data,'$.starts')='' OR unixepoch(json_extract(data,'$.starts'))<=unixepoch())) THEN RAISE(ABORT,'Coupon usage limit reached.') END;
 UPDATE coupons SET used=used+1 WHERE id=NEW.coupon_id;
END;
--> statement-breakpoint
CREATE TRIGGER restore_inventory AFTER UPDATE OF status ON orders WHEN NEW.status IN ('Cancelled','Returned') AND OLD.released=0 BEGIN
 UPDATE variants SET stock=stock+COALESCE((SELECT SUM(quantity) FROM order_items WHERE order_id=NEW.id AND variant_id=variants.id),0) WHERE id IN(SELECT variant_id FROM order_items WHERE order_id=NEW.id);
 UPDATE orders SET released=1,collected=0 WHERE id=NEW.id;
END;
--> statement-breakpoint
CREATE INDEX orders_created_idx ON orders(created_at);
--> statement-breakpoint
CREATE INDEX order_items_order_idx ON order_items(order_id);
--> statement-breakpoint
CREATE INDEX records_kind_idx ON records(kind);
